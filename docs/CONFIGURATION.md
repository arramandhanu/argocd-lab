# Configuration Reference

This document lists all configurable values in the ArgoCD Lab template.

## Variables to Customize

When you fork this repo, update these values to match your environment:

| Variable | Default | Used In | Description |
|----------|---------|---------|-------------|
| `repoURL` | `https://github.com/arramandhanu/argocd-lab.git` | All Application manifests | Your Git repository URL |
| `targetRevision` | `main` | All Application manifests | Git branch to track |
| `namespace` | `argocd` | Application metadata | ArgoCD installation namespace |

## Files That Need Updates

Run `./setup.sh` to update all files automatically, or manually edit:

### ArgoCD Applications
- `bootstrap/root-app.yaml`
- `apps/helm/nginx-helm-dev.yaml`
- `apps/helm/nginx-helm-staging.yaml`
- `apps/helm/nginx-helm-prod.yaml`
- `apps/kustomize/nginx-kustomize-dev.yaml`
- `apps/kustomize/nginx-kustomize-staging.yaml`
- `apps/kustomize/nginx-kustomize-prod.yaml`

### ApplicationSets
- `applicationsets/helm-appset.yaml`
- `applicationsets/kustomize-appset.yaml`

### Projects
- `projects/helm-project.yaml`
- `projects/kustomize-project.yaml`

### Helm Chart
- `helm-charts/nginx/Chart.yaml` (maintainer info)

## Environment-Specific Settings

### Helm Values

| File | Replicas | CPU Limit | Memory Limit |
|------|----------|-----------|--------------|
| `values-dev.yaml` | 1 | 100m | 128Mi |
| `values-staging.yaml` | 2 | 200m | 256Mi |
| `values-prod.yaml` | 3 | 500m | 512Mi |

### Kustomize Overlays

| Overlay | Namespace | Name Prefix | Replicas |
|---------|-----------|-------------|----------|
| `overlays/dev` | nginx-kustomize-dev | dev- | 1 |
| `overlays/staging` | nginx-kustomize-staging | staging- | 2 |
| `overlays/prod` | nginx-kustomize-prod | prod- | 3 |

## Adding New Applications

### For Helm Apps

1. Create chart in `helm-charts/<app-name>/`
2. Add values files for each environment
3. Create Application manifest in `apps/helm/`
4. Or add to `applicationsets/helm-appset.yaml` list

### For Kustomize Apps

1. Create base in `kustomize/<app-name>/base/`
2. Create overlays for environments
3. Create Application manifest in `apps/kustomize/`
4. Or let `applicationsets/kustomize-appset.yaml` auto-discover
