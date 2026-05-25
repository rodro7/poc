#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[installer]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

# ─── Configuration ───────────────────────────────────────────────
MINIKUBE_CPUS=6
MINIKUBE_MEMORY=16384   # 16GB for minikube, leaving 8GB for macOS
MINIKUBE_DISK="60g"
MINIKUBE_DRIVER="docker"
CLUSTER_NAME="poc-cluster"
NAMESPACE="poc"
ISTIO_NAMESPACE="istio-system"

# ─── Step 0: Prerequisites ──────────────────────────────────────
log "Checking prerequisites..."
bash "$SCRIPT_DIR/prerequisites.sh"

# ─── Step 1: Start Minikube ─────────────────────────────────────
log "Starting minikube cluster: $CLUSTER_NAME"
if minikube status -p "$CLUSTER_NAME" &>/dev/null; then
  warn "Cluster '$CLUSTER_NAME' already running, skipping creation"
else
  minikube start \
    --profile="$CLUSTER_NAME" \
    --driver="$MINIKUBE_DRIVER" \
    --cpus="$MINIKUBE_CPUS" \
    --memory="$MINIKUBE_MEMORY" \
    --disk-size="$MINIKUBE_DISK" \
    --kubernetes-version=v1.29.0 \
    --container-runtime=containerd \
    --addons=metrics-server,registry \
    --embed-certs
fi

# Point kubectl to minikube
eval "$(minikube -p "$CLUSTER_NAME" docker-env)"
kubectl config use-context "$CLUSTER_NAME"
success "Minikube cluster ready"

# ─── Step 2: Enable minikube registry ───────────────────────────
log "Enabling minikube registry addon..."
minikube -p "$CLUSTER_NAME" addons enable registry || true
success "Registry addon enabled"

# ─── Step 3: Install Istio ──────────────────────────────────────
log "Installing Istio with default profile..."
istioctl install --set profile=default -y \
  --set meshConfig.accessLogFile=/dev/stdout \
  --set values.pilot.resources.requests.memory=256Mi \
  --set values.pilot.resources.requests.cpu=100m

kubectl wait --for=condition=available deployment/istiod \
  -n "$ISTIO_NAMESPACE" --timeout=300s
success "Istio installed"

# ─── Step 4: Create namespace ───────────────────────────────────
log "Creating namespace: $NAMESPACE"
kubectl apply -f "$INFRA_DIR/k8s/namespaces/namespace.yaml"
success "Namespace created with Istio injection enabled"

# ─── Step 5: Build and push Docker images to minikube registry ──
log "Building Docker images inside minikube..."

log "  Building chat-api..."
docker build -t localhost:5000/chat-api:latest "$INFRA_DIR/docker/chat-api"
docker push localhost:5000/chat-api:latest 2>/dev/null || \
  minikube -p "$CLUSTER_NAME" image load localhost:5000/chat-api:latest
success "  chat-api image built"

log "  Building worker..."
docker build -t localhost:5000/worker:latest "$INFRA_DIR/docker/worker"
docker push localhost:5000/worker:latest 2>/dev/null || \
  minikube -p "$CLUSTER_NAME" image load localhost:5000/worker:latest
success "  worker image built"

log "  Building auth-nats..."
docker build -t localhost:5000/auth-nats:latest "$INFRA_DIR/docker/auth-nats"
docker push localhost:5000/auth-nats:latest 2>/dev/null || \
  minikube -p "$CLUSTER_NAME" image load localhost:5000/auth-nats:latest
success "  auth-nats image built"

# ─── Step 6: Add Helm repos ─────────────────────────────────────
log "Adding Helm repositories..."
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo add nats https://nats-io.github.io/k8s/helm/charts/ 2>/dev/null || true
helm repo add neo4j https://helm.neo4j.com/neo4j 2>/dev/null || true
helm repo update
success "Helm repos updated"

# ─── Step 7: Install PostgreSQL instances ────────────────────────
log "Installing PostgreSQL for chat-api..."
helm upgrade --install postgres-chat bitnami/postgresql \
  -n "$NAMESPACE" \
  -f "$INFRA_DIR/helm-values/postgres-chat-values.yaml" \
  --wait --timeout 300s
success "PostgreSQL (chat-api) installed"

log "Installing PostgreSQL for worker..."
helm upgrade --install postgres-worker bitnami/postgresql \
  -n "$NAMESPACE" \
  -f "$INFRA_DIR/helm-values/postgres-worker-values.yaml" \
  --wait --timeout 300s
success "PostgreSQL (worker) installed"

# ─── Step 8: Install Redis ──────────────────────────────────────
log "Installing Redis (3 replicas)..."
helm upgrade --install redis bitnami/redis \
  -n "$NAMESPACE" \
  -f "$INFRA_DIR/helm-values/redis-values.yaml" \
  --wait --timeout 300s
success "Redis installed"

# ─── Step 9: Install NATS JetStream ─────────────────────────────
log "Installing NATS JetStream cluster..."
helm upgrade --install nats nats/nats \
  -n "$NAMESPACE" \
  -f "$INFRA_DIR/helm-values/nats-values.yaml" \
  --wait --timeout 300s
success "NATS JetStream installed"

# ─── Step 10: Install NATS Leaf Nodes ───────────────────────────
log "Installing NATS Leaf Nodes..."
helm upgrade --install nats-leaf nats/nats \
  -n "$NAMESPACE" \
  -f "$INFRA_DIR/helm-values/nats-leaf-values.yaml" \
  --wait --timeout 300s
success "NATS Leaf Nodes installed"

# Apply NATS HPA
log "Applying NATS HPA for dynamic scaling..."
kubectl apply -f "$INFRA_DIR/k8s/nats/nats-hpa.yaml"
kubectl apply -f "$INFRA_DIR/k8s/nats/nats-leaf-hpa.yaml"
success "NATS HPA applied"

# ─── Step 11: Install Neo4j ─────────────────────────────────────
log "Installing Neo4j..."
helm upgrade --install neo4j neo4j/neo4j \
  -n "$NAMESPACE" \
  -f "$INFRA_DIR/helm-values/neo4j-values.yaml" \
  --wait --timeout 600s
success "Neo4j installed"

# ─── Step 12: Install Arize Phoenix ─────────────────────────────
log "Installing Arize Phoenix..."
kubectl apply -f "$INFRA_DIR/k8s/observability/arize-phoenix/"
kubectl wait --for=condition=available deployment/arize-phoenix \
  -n "$NAMESPACE" --timeout=300s
success "Arize Phoenix installed"

# ─── Step 13: Deploy application services ───────────────────────
log "Deploying chat-api service..."
kubectl apply -f "$INFRA_DIR/k8s/services/chat-api/"
kubectl wait --for=condition=available deployment/chat-api \
  -n "$NAMESPACE" --timeout=300s
success "chat-api deployed"

log "Deploying worker service..."
kubectl apply -f "$INFRA_DIR/k8s/services/worker/"
kubectl wait --for=condition=available deployment/worker \
  -n "$NAMESPACE" --timeout=300s
success "worker deployed"

log "Deploying auth-nats service..."
kubectl apply -f "$INFRA_DIR/k8s/services/auth-nats/"
kubectl wait --for=condition=available deployment/auth-nats \
  -n "$NAMESPACE" --timeout=300s
success "auth-nats deployed"

# ─── Step 14: Apply Istio Gateway and routing ───────────────────
log "Applying Istio Gateway and VirtualServices..."
kubectl apply -f "$INFRA_DIR/k8s/gateway/"
success "Istio Gateway configured"

# ─── Done ────────────────────────────────────────────────────────
echo ""
echo "==========================================="
echo -e "${GREEN} Installation Complete! ${NC}"
echo "==========================================="
echo ""
echo "Cluster: $CLUSTER_NAME"
echo "Namespace: $NAMESPACE"
echo ""
echo "To access services via Istio ingress gateway:"
echo "  minikube -p $CLUSTER_NAME tunnel"
echo ""
echo "Then access:"
echo "  Chat API:      http://localhost/api/chat"
echo "  Worker API:    http://localhost/api/worker"
echo "  Arize Phoenix: http://localhost/phoenix"
echo ""
echo "Useful commands:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  kubectl get svc -n $NAMESPACE"
echo "  istioctl dashboard kiali"
echo ""
