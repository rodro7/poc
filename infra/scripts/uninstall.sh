#!/usr/bin/env bash
set -euo pipefail

KUBE_CONTEXT="rancher-desktop"
NAMESPACE="poc"
HARBOR_NAMESPACE="harbor"

RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${BLUE}[uninstaller]${NC} $*"; }

echo -e "${RED}This will remove all POC namespaces and Harbor from the Rancher Desktop cluster.${NC}"
echo -e "${RED}Rancher Desktop itself will NOT be stopped.${NC}"
read -rp "Are you sure? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

kubectl config use-context "$KUBE_CONTEXT"

log "Deleting application namespace '$NAMESPACE'..."
kubectl delete namespace "$NAMESPACE" --ignore-not-found=true

log "Uninstalling Istio..."
helm uninstall istiod -n istio-system --ignore-not-found 2>/dev/null || true
helm uninstall istio-base -n istio-system --ignore-not-found 2>/dev/null || true
kubectl delete namespace istio-system --ignore-not-found=true 2>/dev/null || true

log "Uninstalling Harbor..."
helm uninstall harbor -n "$HARBOR_NAMESPACE" --ignore-not-found 2>/dev/null || true
kubectl delete namespace "$HARBOR_NAMESPACE" --ignore-not-found=true

log "Uninstalling nginx ingress controller..."
helm uninstall ingress-nginx -n ingress-nginx --ignore-not-found 2>/dev/null || true
kubectl delete namespace ingress-nginx --ignore-not-found=true

echo -e "${GREEN}Uninstall complete. Rancher Desktop cluster is still running.${NC}"
