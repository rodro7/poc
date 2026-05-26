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
KUBE_CONTEXT="rancher-desktop"
NAMESPACE="poc"
HARBOR_NAMESPACE="harbor"
ISTIO_NAMESPACE="istio-system"
HARBOR_HOST="harbor.local"
HARBOR_USER="admin"
HARBOR_PASSWORD="Harbor12345"
HARBOR_PROJECT="poc"
HARBOR_REGISTRY="${HARBOR_HOST}/${HARBOR_PROJECT}"

# ─── Step 0: Prerequisites ──────────────────────────────────────
log "Checking prerequisites..."
bash "$SCRIPT_DIR/prerequisites.sh"

# ─── Step 1: Set kubectl context to Rancher Desktop ─────────────
log "Setting kubectl context to: $KUBE_CONTEXT"
kubectl config use-context "$KUBE_CONTEXT"
success "Context set to $KUBE_CONTEXT"

# ─── Step 2: Install nginx ingress controller (needed for Harbor) ─
log "Installing nginx ingress controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=NodePort \
  --wait --timeout 120s
success "nginx ingress controller installed"

# ─── Step 3: Install Harbor ─────────────────────────────────────
log "Installing Harbor registry..."
helm repo add harbor https://helm.goharbor.io 2>/dev/null || true
helm repo update
kubectl apply -f "$INFRA_DIR/k8s/namespaces/harbor-namespace.yaml"
helm upgrade --install harbor harbor/harbor \
  -n "$HARBOR_NAMESPACE" \
  -f "$INFRA_DIR/helm-values/harbor-values.yaml" \
  --wait --timeout 600s
success "Harbor installed"

# Resolve Harbor ingress IP and add /etc/hosts entry if needed
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")

if [[ -n "$INGRESS_IP" ]] && ! grep -q "$HARBOR_HOST" /etc/hosts; then
  warn "Add the following line to /etc/hosts (requires sudo):"
  warn "  ${INGRESS_IP}  ${HARBOR_HOST}"
  warn "Run: echo '${INGRESS_IP}  ${HARBOR_HOST}' | sudo tee -a /etc/hosts"
fi

# ─── Step 4: Create Harbor project 'poc' via API ─────────────────
log "Creating Harbor project '${HARBOR_PROJECT}'..."
curl -s -o /dev/null -w "%{http_code}" \
  -u "${HARBOR_USER}:${HARBOR_PASSWORD}" \
  -X POST "http://${HARBOR_HOST}/api/v2.0/projects" \
  -H "Content-Type: application/json" \
  -d "{\"project_name\":\"${HARBOR_PROJECT}\",\"public\":false,\"metadata\":{\"public\":\"false\"}}" \
  2>/dev/null | grep -q "201\|409" || warn "Harbor project creation may have failed - check manually"
success "Harbor project '${HARBOR_PROJECT}' ready"

# ─── Step 5: Docker login to Harbor ─────────────────────────────
log "Logging into Harbor registry..."
echo "$HARBOR_PASSWORD" | docker login "$HARBOR_HOST" \
  --username "$HARBOR_USER" --password-stdin
success "Logged into Harbor"

# ─── Step 6: Build and push Docker images to Harbor ─────────────
log "Building and pushing Docker images to Harbor..."

log "  Building chat-api..."
docker build --platform linux/arm64 \
  -t "${HARBOR_REGISTRY}/chat-api:latest" \
  "$INFRA_DIR/docker/chat-api"
docker push "${HARBOR_REGISTRY}/chat-api:latest"
success "  chat-api pushed to ${HARBOR_REGISTRY}/chat-api:latest"

log "  Building worker..."
docker build --platform linux/arm64 \
  -t "${HARBOR_REGISTRY}/worker:latest" \
  "$INFRA_DIR/docker/worker"
docker push "${HARBOR_REGISTRY}/worker:latest"
success "  worker pushed to ${HARBOR_REGISTRY}/worker:latest"

log "  Building auth-nats..."
docker build --platform linux/arm64 \
  -t "${HARBOR_REGISTRY}/auth-nats:latest" \
  "$INFRA_DIR/docker/auth-nats"
docker push "${HARBOR_REGISTRY}/auth-nats:latest"
success "  auth-nats pushed to ${HARBOR_REGISTRY}/auth-nats:latest"

# ─── Step 7: Create poc namespace ───────────────────────────────
log "Installing Istio with default profile..."
helm repo add istio https://istio-release.storage.googleapis.com/charts 2>/dev/null || true
helm repo update
kubectl create namespace "$ISTIO_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install istio-base istio/base -n "$ISTIO_NAMESPACE" --wait --timeout 120s
helm upgrade --install istiod istio/istiod -n "$ISTIO_NAMESPACE" \
  --set pilot.resources.requests.memory=256Mi \
  --set pilot.resources.requests.cpu=100m \
  --set meshConfig.accessLogFile=/dev/stdout \
  --wait --timeout 300s
success "Istio installed via Helm"

# ─── Step 8: Create poc namespace ───────────────────────────────
log "Creating namespace: $NAMESPACE"
kubectl apply -f "$INFRA_DIR/k8s/namespaces/namespace.yaml"
success "Namespace created with Istio injection enabled"

# ─── Step 9: Create Harbor pull secret in poc namespace ─────────
log "Creating Harbor imagePullSecret in namespace '$NAMESPACE'..."
kubectl create secret docker-registry harbor-pull-secret \
  --namespace="$NAMESPACE" \
  --docker-server="$HARBOR_HOST" \
  --docker-username="$HARBOR_USER" \
  --docker-****** \
  --docker-email="admin@example.com" \
  --dry-run=client -o yaml | kubectl apply -f -
success "Harbor pull secret created"

# ─── Step 10: Add Helm repos ────────────────────────────────────
log "Adding Helm repositories..."
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo add nats https://nats-io.github.io/k8s/helm/charts/ 2>/dev/null || true
helm repo add neo4j https://helm.neo4j.com/neo4j 2>/dev/null || true
helm repo update
success "Helm repos updated"

# ─── Step 11: Install PostgreSQL instances ───────────────────────
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

# ─── Step 12: Install Redis ─────────────────────────────────────
log "Installing Redis (3 replicas)..."
helm upgrade --install redis bitnami/redis \
  -n "$NAMESPACE" \
  -f "$INFRA_DIR/helm-values/redis-values.yaml" \
  --wait --timeout 300s
success "Redis installed"

# ─── Step 13: Install NATS JetStream ────────────────────────────
log "Installing NATS JetStream cluster..."
helm upgrade --install nats nats/nats \
  -n "$NAMESPACE" \
  -f "$INFRA_DIR/helm-values/nats-values.yaml" \
  --wait --timeout 300s
success "NATS JetStream installed"

log "Installing NATS Leaf Nodes..."
helm upgrade --install nats-leaf nats/nats \
  -n "$NAMESPACE" \
  -f "$INFRA_DIR/helm-values/nats-leaf-values.yaml" \
  --wait --timeout 300s
success "NATS Leaf Nodes installed"

log "Applying NATS HPA for dynamic scaling..."
kubectl apply -f "$INFRA_DIR/k8s/nats/nats-hpa.yaml"
kubectl apply -f "$INFRA_DIR/k8s/nats/nats-leaf-hpa.yaml"
success "NATS HPA applied"

# ─── Step 14: Install Neo4j ─────────────────────────────────────
log "Installing Neo4j..."
helm upgrade --install neo4j neo4j/neo4j \
  -n "$NAMESPACE" \
  -f "$INFRA_DIR/helm-values/neo4j-values.yaml" \
  --wait --timeout 600s
success "Neo4j installed"

# ─── Step 15: Install Arize Phoenix ─────────────────────────────
log "Installing Arize Phoenix..."
kubectl apply -f "$INFRA_DIR/k8s/observability/arize-phoenix/"
kubectl wait --for=condition=available deployment/arize-phoenix \
  -n "$NAMESPACE" --timeout=300s
success "Arize Phoenix installed"

# ─── Step 16: Deploy application services ───────────────────────
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

# ─── Step 17: Apply Istio Gateway and routing ───────────────────
log "Applying Istio Gateway and VirtualServices..."
kubectl apply -f "$INFRA_DIR/k8s/gateway/"
success "Istio Gateway configured"

# ─── Done ────────────────────────────────────────────────────────
echo ""
echo "==========================================="
echo -e "${GREEN} Installation Complete! ${NC}"
echo "==========================================="
echo ""
echo "Cluster: Rancher Desktop (K3s)"
echo "Registry: Harbor @ http://${HARBOR_HOST}"
echo "Namespace: $NAMESPACE"
echo ""
echo "Harbor UI:        http://${HARBOR_HOST}  (admin / ${HARBOR_PASSWORD})"
echo ""
echo "To access services via Istio ingress gateway:"
echo "  kubectl -n istio-system port-forward svc/istio-ingressgateway 8080:80"
echo ""
echo "Then access:"
echo "  Chat API:      http://localhost:8080/api/chat"
echo "  Worker API:    http://localhost:8080/api/worker"
echo "  Arize Phoenix: http://localhost:8080/phoenix"
echo ""
echo "Useful commands:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  kubectl get svc -n $NAMESPACE"
echo "  istioctl dashboard kiali"
echo ""
