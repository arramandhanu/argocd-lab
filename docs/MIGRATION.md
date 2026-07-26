# Migration Guide

Migrating existing Kubernetes workloads to GitOps with ArgoCD.

## From Manual kubectl to GitOps

### 1. Export Current State

```bash
# Export existing deployments
kubectl get deployment -n <namespace> -o yaml > backup-deployment.yaml
kubectl get service -n <namespace> -o yaml > backup-service.yaml
kubectl get configmap -n <namespace> -o yaml > backup-configmap.yaml
```

### 2. Convert to Helm or Kustomize

**Option A: Helm (recommended for complex apps)**
```bash
helm create <app-name>
# Move your manifests to templates/
# Update values.yaml with your configurations
```

**Option B: Kustomize (for simple overlays)**
```bash
mkdir -p base/
# Copy manifests to base/
# Create overlays/ for environments
```

### 3. Create ArgoCD Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR/REPO.git
    targetRevision: main
    path: path/to/chart
  destination:
    server: https://kubernetes.default.svc
    namespace: <namespace>
```

### 4. Sync and Verify

```bash
argocd app create my-app
argocd app sync my-app
argocd app get my-app
```

## From kubectl apply to ArgoCD Sync

| Old Way | GitOps Way |
|---------|-----------|
| `kubectl apply -f app.yaml` | `git push` + ArgoCD sync |
| `kubectl edit` | Edit YAML + PR |
| `kubectl delete` | Remove YAML + PR |

## Common Pitfalls

1. **Drift detection**: ArgoCD will detect manual changes - use `ignoreDifferences` for intentional drifts
2. **Secrets**: Never commit raw secrets - use Sealed Secrets or ESO
3. **Image tags**: Pin to digests for immutability
