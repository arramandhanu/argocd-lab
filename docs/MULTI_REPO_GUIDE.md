# Multi-Repo Microservices Pattern

This guide explains how to manage **multiple microservices in separate repositories** using ArgoCD.

## Two Approaches

| Approach | Description | Best For |
|----------|-------------|----------|
| **Monorepo** | All configs in this single repo | Small teams, simple setups |
| **Multi-repo** | Each microservice in its own repo, this repo manages ArgoCD Apps | Large teams, 10+ services |

## How Multi-Repo Works

```
┌─────────────────────────────────────────────────────────────┐
│                    This ArgoCD Lab Repo                     │
│                                                             │
│  apps/external/              Points to external repos       │
│  ├── user-service-dev.yaml   → github.com/org/user-service  │
│  ├── order-service-dev.yaml  → gitlab.com/org/order-service │
│  └── payment-service.yaml    → bitbucket.org/org/payment    │
│                                                             │
│  config/microservices.conf   Inventory of all services      │
│  add-microservice.sh         Generator script               │
└─────────────────────────────────────────────────────────────┘
```

**The key insight**: Your microservice repos contain the actual Helm charts or Kustomize manifests. This ArgoCD repo only contains pointers (ArgoCD Applications) to those repos.

## Quick Start

### Option 1: Add One Service at a Time

```bash
./add-microservice.sh --single
```

Interactive prompts:
```
Service Name: user-service
Repository URL: https://github.com/myorg/user-service.git
Path to manifests: deploy/helm
Type: 1) Helm  2) Kustomize
Environments: dev,staging,prod
Branch: main
```

This generates 3 files in `apps/external/`:
- `user-service-dev.yaml`
- `user-service-staging.yaml`
- `user-service-prod.yaml`

### Option 2: Batch Generate from Config

1. Edit `config/microservices.conf`:

```conf
# Format: name|repo_url|path|type|environments|branch
user-service|https://github.com/myorg/user-service.git|deploy/helm|helm|dev,staging,prod|main
order-service|https://github.com/myorg/order-service.git|deploy/helm|helm|dev,staging,prod|main
payment-service|https://github.com/myorg/payment-service.git|k8s|kustomize|staging,prod|main
inventory-service|https://gitlab.com/myorg/inventory.git|charts/app|helm|dev,prod|main
```

2. Generate all:

```bash
./add-microservice.sh
```

### Option 3: Use ApplicationSet

For dynamic generation, use ApplicationSet:

```bash
./add-microservice.sh --appset
```

This creates `applicationsets/microservices-appset.yaml` that auto-generates apps from your config.

## Expected Microservice Repo Structure

Your microservice repos should have Helm charts or Kustomize manifests:

### For Helm-based Service

```
user-service/
├── src/                    # Your application code
├── deploy/
│   └── helm/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-staging.yaml
│       ├── values-prod.yaml
│       └── templates/
│           ├── deployment.yaml
│           └── service.yaml
```

### For Kustomize-based Service

```
order-service/
├── src/                    # Your application code
├── k8s/
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── overlays/
│       ├── dev/
│       │   └── kustomization.yaml
│       ├── staging/
│       │   └── kustomization.yaml
│       └── prod/
│           └── kustomization.yaml
```

## Managing Microservices

For large-scale deployments:

1. **Use the config file**: Add all repo microservices to `config/microservices.conf`
2. **Generate once**: Run `./add-microservice.sh`
3. **Commit and push**: Git push to trigger ArgoCD sync
4. **Use ApplicationSet**: For even more dynamic management

### Sample Config for 35 Services

```conf
# Core services
user-service|https://github.com/myorg/user-service.git|deploy/helm|helm|dev,staging,prod|main
auth-service|https://github.com/myorg/auth-service.git|deploy/helm|helm|dev,staging,prod|main
gateway-service|https://github.com/myorg/gateway.git|deploy/helm|helm|dev,staging,prod|main

# Business services
order-service|https://github.com/myorg/order-service.git|deploy/helm|helm|dev,staging,prod|main
payment-service|https://github.com/myorg/payment.git|deploy/helm|helm|staging,prod|main
inventory-service|https://github.com/myorg/inventory.git|deploy/helm|helm|dev,staging,prod|main

# ...add more as needed
```

## Best Practices

1. **Use consistent paths**: Keep `deploy/helm` or `k8s/overlays` across all repos
2. **Version your configs**: Tag releases in microservice repos
3. **Environment parity**: Use same structure for dev/staging/prod
4. **Secrets management**: Use Sealed Secrets or External Secrets Operator
5. **RBAC**: Create ArgoCD Projects per team
