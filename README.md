<p align="center">
  <img src="https://raw.githubusercontent.com/cncf/artwork/master/projects/argo/icon/color/argo-icon-color.svg" width="100" alt="ArgoCD"/>
</p>

<h1 align="center">ArgoCD App-of-Apps Lab</h1>

<p align="center">
  Production-ready GitOps template with Helm and Kustomize examples
</p>

<p align="center">
  <a href="https://argoproj.github.io/argo-cd/"><img src="https://img.shields.io/badge/ArgoCD-v2.9+-00ADD8?style=for-the-badge&logo=argo&logoColor=white" alt="ArgoCD"/></a>
  <a href="https://kubernetes.io/"><img src="https://img.shields.io/badge/Kubernetes-v1.28+-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes"/></a>
  <a href="https://helm.sh/"><img src="https://img.shields.io/badge/Helm-v3.13+-0F1689?style=for-the-badge&logo=helm&logoColor=white" alt="Helm"/></a>
  <a href="https://kustomize.io/"><img src="https://img.shields.io/badge/Kustomize-v5.0+-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kustomize"/></a>
</p>

---

## Overview

A template repo for setting up GitOps workflows with ArgoCD. Includes working examples of Helm charts, Kustomize overlays, and the App-of-Apps pattern. Fork it, configure it, and deploy.

---

## Choose Your Pattern

<table>
<tr>
<td width="50%" valign="top">

### Monorepo

**All application configs live in this single repository.**

Your Helm charts and Kustomize overlays are stored here alongside the ArgoCD Application manifests. When you push changes, ArgoCD syncs everything from one place.

Best for:
- Small to medium teams
- Centralized config management
- Learning and experimentation

```bash
./setup.sh
kubectl apply -f bootstrap/root-app.yaml
```

</td>
<td width="50%" valign="top">

### Multi-Repo

**Each microservice has its own repository with its own manifests.**

This ArgoCD repo only stores *pointers* to external service repos. Each team owns their service repo, and ArgoCD pulls manifests directly from each source.

Best for:
- Large organizations (10+ services)
- Independent team ownership
- Microservices architecture

```bash
./add-microservice.sh
kubectl apply -f apps/external/
```

[Full guide →](docs/MULTI_REPO_GUIDE.md)

</td>
</tr>
</table>

---

## Sync Policies

| Environment | Behavior |
|-------------|----------|
| Dev | Auto-sync on merge |
| Staging | Auto-sync on merge |
| **Prod** | **Manual trigger only** |

[Sync policies guide →](docs/SYNC_POLICIES.md)

---

## Quick Start

```bash
# 1. Fork and clone
git clone https://github.com/YOUR-USERNAME/argocd-lab.git
cd argocd-lab

# 2. Configure (supports GitHub, GitLab, Bitbucket, Azure DevOps)
./setup.sh

# 3. Commit and push
git add -A && git commit -m "Configure repo" && git push

# 4. Deploy
kubectl apply -f bootstrap/root-app.yaml
```

---

## Architecture

![App-of-Apps Architecture](docs/images/architecture.png)

![GitOps Workflow](docs/images/gitops-workflow.png)

---

## What's Included

| Component | Description |
|-----------|-------------|
| `bootstrap/` | Root application that deploys everything else |
| `apps/helm/` | Helm-based apps for dev, staging, prod |
| `apps/kustomize/` | Kustomize-based apps for dev, staging, prod |
| `apps/external/` | Apps pointing to external microservice repos |
| `helm-charts/nginx/` | Complete Helm chart with values per environment |
| `kustomize/nginx/` | Kustomize base + overlays |
| `applicationsets/` | Auto-generate apps with list or git generators |
| `config/` | Microservices inventory for multi-repo pattern |

---

## Prerequisites

- Kubernetes cluster (minikube, kind, k3s, EKS, GKE, AKS)
- ArgoCD installed ([docs](https://argo-cd.readthedocs.io/en/stable/getting_started/))
- kubectl configured

---

## Deployment Options

**App-of-Apps** (recommended)
```bash
kubectl apply -f bootstrap/root-app.yaml
```

**Individual apps**
```bash
kubectl apply -f apps/helm/nginx-helm-dev.yaml
```

**ApplicationSets**
```bash
kubectl apply -f applicationsets/helm-appset.yaml
```

**External microservices**
```bash
./add-microservice.sh --single
```

---

## Local Testing

```bash
# Helm
helm lint helm-charts/nginx
helm template test helm-charts/nginx -f helm-charts/nginx/values-dev.yaml

# Kustomize
kustomize build kustomize/nginx/overlays/dev
```

---

## Environment Configs

| Env | Replicas | CPU | Memory |
|-----|----------|-----|--------|
| Dev | 1 | 25m | 32Mi |
| Staging | 2 | 100m | 128Mi |
| Prod | 3 | 200m | 256Mi |

---

## Documentation

- [Configuration Reference](docs/CONFIGURATION.md)
- [Multi-Repo Guide](docs/MULTI_REPO_GUIDE.md)
- [Sync Policies](docs/SYNC_POLICIES.md)

---

## Contributing

PRs welcome. Open an issue first for major changes.

---

## License

<a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat-square" alt="MIT License"/></a>

This project is licensed under the **MIT License** - free for personal and commercial use.

See [LICENSE](LICENSE) for full terms and third-party attributions.
