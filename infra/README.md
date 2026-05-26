# POC Infrastructure Installer — Rancher Desktop + Harbor

Kubernetes infrastructure with Istio service mesh, using **Rancher Desktop** (K3s) as the local cluster and **Harbor** as the private container registry.

## Architecture

```
                    ┌─────────────────────────┐
                    │    Istio Gateway (:80)   │
                    └────────┬────────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
        ┌─────▼─────┐ ┌─────▼─────┐ ┌──────▼──────┐
        │  Chat API  │ │  Worker   │ │  Auth NATS  │
        │  (Python)  │ │ (Python)  │ │    (Go)     │
        │  FastAPI   │ │ LangGraph │ │  JWT Auth   │
        └─────┬──────┘ └─────┬─────┘ └──────┬──────┘
              │              │               │
    ┌─────────┼──────────────┼───────────────┤
    │         │              │               │
┌───▼───┐ ┌──▼──┐    ┌──────▼──────┐  ┌─────▼─────┐
│Postgres│ │Redis│    │   Neo4j     │  │   NATS    │
│(chat)  │ │(3r) │    │ + Graphiti  │  │ JetStream │
└────────┘ └─────┘    └─────────────┘  │  (3→5)   │
                                       └─────┬─────┘
┌────────┐                                   │
│Postgres│                             ┌─────▼─────┐
│(worker)│                             │NATS Leaf  │
└────────┘                             │  (3→5)    │
                                       └───────────┘
┌────────────────┐   ┌─────────────┐
│ Harbor Registry│   │Arize Phoenix│
│  harbor.local  │   │(Observ.)    │
└────────────────┘   └─────────────┘
```

## Prerequisites

- macOS with Apple Silicon (M3 Pro, 24GB RAM)
- [Rancher Desktop](https://rancherdesktop.io/) — provides K3s + kubectl + docker/nerdctl
- [Homebrew](https://brew.sh)

### Install required CLI tools

```bash
brew install --cask rancher          # Rancher Desktop (includes rdctl)
brew install helm istioctl
```

Open **Rancher Desktop**, choose **dockerd** as the container runtime, and wait for the green status indicator before running the installer.

### /etc/hosts entry

After installing Harbor you will need to add the Harbor hostname to `/etc/hosts`.
The installer will print the exact line to add.

## Quick Start

```bash
chmod +x infra/scripts/*.sh
./infra/scripts/install.sh
```

## Components

| Component | Type | Replicas | Image Source |
|-----------|------|----------|--------------|
| Chat API | Python FastAPI | 1 | harbor.local/poc/chat-api |
| Worker | Python LangGraph FastAPI | 1 | harbor.local/poc/worker |
| Auth NATS | Go JWT service | 1 | harbor.local/poc/auth-nats |
| NATS JetStream | Helm (nats/nats) | 3 (HPA → 5) | nats:latest |
| NATS Leaf | Helm (nats/nats) | 3 (HPA → 5) | nats:latest |
| PostgreSQL (chat) | Helm (bitnami) | 1 | bitnami/postgresql |
| PostgreSQL (worker) | Helm (bitnami) | 1 | bitnami/postgresql |
| Redis | Helm (bitnami) | 3 replicas | bitnami/redis |
| Neo4j | Helm (neo4j/neo4j) | 1 | neo4j |
| Arize Phoenix | K8s manifest | 1 | arizephoenix/phoenix |
| **Harbor** | Helm (goharbor/harbor) | — | goharbor/harbor-core |
| nginx ingress | Helm | — | (required for Harbor) |

## Harbor Registry

Harbor is deployed in the `harbor` namespace and exposed at `http://harbor.local`.

| Field | Value |
|-------|-------|
| URL | http://harbor.local |
| Username | admin |
| Default password | Harbor12345 (change after first login) |
| Project | poc |

Images are tagged and pushed as:
```
harbor.local/poc/chat-api:latest
harbor.local/poc/worker:latest
harbor.local/poc/auth-nats:latest
```

All application deployments reference `harbor-pull-secret` (created by `install.sh`).

### Rebuilding and pushing a single image

```bash
# Log in
echo "Harbor12345" | docker login harbor.local -u admin --password-stdin

# Rebuild and push chat-api
docker build --platform linux/arm64 \
  -t harbor.local/poc/chat-api:latest \
  infra/docker/chat-api
docker push harbor.local/poc/chat-api:latest

# Roll out the new image
kubectl rollout restart deployment/chat-api -n poc
```

## Resource Allocation (Mac M3 Pro 24GB)

- **Rancher Desktop / K3s**: configure via Rancher Desktop Preferences → Virtual Machine
  - Recommended: 6 CPUs, 16GB RAM
- **macOS**: ~8GB reserved for system operations

## NATS Dynamic Scaling

Both NATS JetStream and Leaf Node clusters scale between 3–5 replicas:
- **Scale-up trigger**: CPU > 70% OR Memory > 75%
- **Scale-down stabilization**: 5 minutes

## Accessing Services

Forward the Istio ingress gateway:
```bash
kubectl -n istio-system port-forward svc/istio-ingressgateway 8080:80
```

Then access:
- **Chat API**: http://localhost:8080/api/chat
- **Worker API**: http://localhost:8080/api/worker
- **Auth**: http://localhost:8080/auth/validate
- **Arize Phoenix**: http://localhost:8080/phoenix
- **Harbor UI**: http://harbor.local

## Directory Structure

```
infra/
├── scripts/
│   ├── install.sh              # Main installer (Rancher + Harbor)
│   ├── uninstall.sh            # Cleanup (leaves Rancher Desktop running)
│   └── prerequisites.sh        # Prerequisite checker
├── docker/
│   ├── chat-api/               # Python FastAPI Dockerfile + source
│   ├── worker/                 # Python LangGraph Dockerfile + source
│   └── auth-nats/              # Go JWT auth Dockerfile + source
├── helm-values/
│   ├── harbor-values.yaml      # Harbor registry configuration
│   ├── postgres-chat-values.yaml
│   ├── postgres-worker-values.yaml
│   ├── redis-values.yaml
│   ├── nats-values.yaml
│   ├── nats-leaf-values.yaml
│   └── neo4j-values.yaml
└── k8s/
    ├── namespaces/             # poc + harbor namespace manifests
    ├── gateway/                # Istio Gateway + VirtualService
    ├── services/               # App deployments + services (Harbor images)
    ├── nats/                   # HPA for NATS scaling
    └── observability/          # Arize Phoenix
```

## Uninstall

```bash
./infra/scripts/uninstall.sh
```

This removes the `poc` and `harbor` namespaces and Istio. **Rancher Desktop is not stopped.**

## Notes

- Passwords in this setup are for **development only**. Use proper secret management (e.g. Vault, Kubernetes Secrets with external-secrets) for production.
- Istio sidecar injection is disabled for stateful services (PostgreSQL, Redis, NATS, Neo4j).
- The `--platform linux/arm64` flag ensures images are built for Apple Silicon.
