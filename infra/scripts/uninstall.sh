#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="poc-cluster"
NAMESPACE="poc"

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${BLUE}[uninstaller]${NC} $*"; }

echo -e "${RED}This will destroy the entire '$CLUSTER_NAME' minikube cluster.${NC}"
read -rp "Are you sure? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

log "Deleting Kubernetes resources in namespace $NAMESPACE..."
kubectl delete namespace "$NAMESPACE" --ignore-not-found=true 2>/dev/null || true

log "Uninstalling Istio..."
istioctl uninstall --purge -y 2>/dev/null || true
kubectl delete namespace istio-system --ignore-not-found=true 2>/dev/null || true

log "Deleting minikube cluster: $CLUSTER_NAME..."
minikube delete -p "$CLUSTER_NAME" 2>/dev/null || true

echo -e "${GREEN}Uninstall complete.${NC}"
