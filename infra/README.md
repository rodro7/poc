# POC Infrastructure Installer

Minikube-based Kubernetes infrastructure with Istio service mesh for a chat application stack.

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
┌─────────────┐
│Arize Phoenix│  (Observability)
└─────────────┘
```

## Prerequisites

- macOS with Apple Silicon (M3 Pro recommended, 24GB RAM)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Homebrew](https://brew.sh)

Install required tools:
```bash
brew install minikube kubectl helm istioctl
```

## Quick Start

```bash
# Make scripts executable
chmod +x infra/scripts/*.sh

# Run the installer
./infra/scripts/install.sh
```

## Components

| Component | Type | Replicas | Image |
|-----------|------|----------|-------|
| Chat API | Python FastAPI | 1 | Local registry |
| Worker | Python LangGraph FastAPI | 1 | Local registry |
| Auth NATS | Go JWT service | 1 | Local registry |
| NATS JetStream | Helm chart | 3 (HPA → 5) | nats:latest |
| NATS Leaf | Helm chart | 3 (HPA → 5) | nats:latest |
| PostgreSQL (chat) | Helm chart | 1 | bitnami/postgresql |
| PostgreSQL (worker) | Helm chart | 1 | bitnami/postgresql |
| Redis | Helm chart | 3 replicas | bitnami/redis |
| Neo4j | Helm chart | 1 | neo4j |
| Arize Phoenix | K8s manifest | 1 | arizephoenix/phoenix |

## Resource Allocation (Mac M3 Pro 24GB)

- **Minikube**: 6 CPUs, 16GB RAM, 60GB disk
- **macOS reserved**: ~8GB RAM for system operations

## NATS Dynamic Scaling

Both NATS JetStream and Leaf Node clusters are configured with HPA:
- **Min replicas**: 3
- **Max replicas**: 5
- **Scale-up trigger**: CPU > 70% OR Memory > 75%
- **Scale-down stabilization**: 5 minutes

## Accessing Services

After installation, start the tunnel:
```bash
minikube -p poc-cluster tunnel
```

Then access:
- **Chat API**: http://localhost/api/chat
- **Worker API**: http://localhost/api/worker
- **Auth**: http://localhost/auth/validate
- **Arize Phoenix**: http://localhost/phoenix

## Directory Structure

```
infra/
├── scripts/
│   ├── install.sh          # Main installer
│   ├── uninstall.sh        # Cleanup script
│   └── prerequisites.sh    # Prerequisite checker
├── docker/
│   ├── chat-api/           # Chat API Dockerfile + source
│   ├── worker/             # Worker Dockerfile + source
│   └── auth-nats/          # Auth NATS Go service
├── helm-values/
│   ├── postgres-chat-values.yaml
│   ├── postgres-worker-values.yaml
│   ├── redis-values.yaml
│   ├── nats-values.yaml
│   ├── nats-leaf-values.yaml
│   └── neo4j-values.yaml
└── k8s/
    ├── namespaces/         # Namespace with Istio injection
    ├── gateway/            # Istio Gateway + VirtualService
    ├── services/           # App deployments + services
    ├── nats/               # HPA for NATS scaling
    └── observability/      # Arize Phoenix
```

## Uninstall

```bash
./infra/scripts/uninstall.sh
```

## Notes

- All passwords in this setup are for **development only**. Use Kubernetes Secrets with proper secret management for production.
- The Istio sidecar injection is disabled for stateful services (PostgreSQL, Redis, NATS, Neo4j) to avoid connectivity issues.
- Docker images are built inside the minikube Docker environment and pushed to minikube's built-in registry.
