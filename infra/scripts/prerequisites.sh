#!/usr/bin/env bash
set -euo pipefail

# Prerequisites checker for Mac M3 Pro (Rancher Desktop + Harbor)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_command() {
  local cmd="$1"
  local install_hint="$2"
  if command -v "$cmd" &>/dev/null; then
    echo -e "${GREEN}✓${NC} $cmd found: $(command -v "$cmd")"
    return 0
  else
    echo -e "${RED}✗${NC} $cmd not found. Install with: ${YELLOW}${install_hint}${NC}"
    return 1
  fi
}

echo "=== Checking Prerequisites (Rancher Desktop + Harbor) ==="
echo ""

MISSING=0

check_command "brew"      "See https://brew.sh" || MISSING=1
check_command "rdctl"     "brew install --cask rancher" || MISSING=1
check_command "kubectl"   "brew install kubectl" || MISSING=1
check_command "helm"      "brew install helm" || MISSING=1
check_command "istioctl"  "brew install istioctl" || MISSING=1
check_command "docker"    "Included with Rancher Desktop" || MISSING=1

echo ""

# Verify Rancher Desktop cluster is reachable
if kubectl cluster-info --context rancher-desktop &>/dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} Rancher Desktop cluster is reachable"
else
  echo -e "${RED}✗${NC} Rancher Desktop cluster not reachable."
  echo "   Start Rancher Desktop from the Applications menu, wait for the green light."
  MISSING=1
fi

# Check architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
  echo -e "${GREEN}✓${NC} ARM64 architecture detected (Apple Silicon)"
else
  echo -e "${YELLOW}!${NC} Architecture: $ARCH (expected arm64 for M3 Pro)"
fi

# Check available memory
TOTAL_MEM_GB=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1/1024/1024/1024}' || echo "unknown")
echo -e "  Total system memory: ${TOTAL_MEM_GB}GB"

if [[ "$MISSING" -ne 0 ]]; then
  echo ""
  echo -e "${RED}Some prerequisites are missing. Please install them before continuing.${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}All prerequisites satisfied!${NC}"
