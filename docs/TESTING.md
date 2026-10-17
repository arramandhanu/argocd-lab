# Testing Guide

Workflow to test ArgoCD Lab after clone and setup.

## Prerequisites

```bash
# Install tools
brew install kubectl helm kustomize argocd  # macOS
# or
apt install kubectl helm kustomize          # Linux

# Verify installations
kubectl version --client
helm version
kustomize version
argocd version
```

## 1. Clone and Setup

```bash
git clone https://github.com/YOUR-USERNAME/argocd-lab.git
cd argocd-lab

# Configure for your environment
./setup.sh
# Select: GitHub, enter your username, repository name
```

## 2. Validate All Manifests

```bash
# Option A: Run validation script
./scripts/validate.sh

# Option B: Manual validation
helm lint helm-charts/nginx

helm template test helm-charts/nginx -f helm-charts/nginx/values-dev.yaml
helm template test helm-charts/nginx -f helm-charts/nginx/values-staging.yaml
helm template test helm-charts/nginx -f helm-charts/nginx/values-prod.yaml

kustomize build kustomize/nginx/overlays/dev
kustomize build kustomize/nginx/overlays/staging
kustomize build kustomize/nginx/overlays/prod
```

## 3. Test on Local Kubernetes

### Using kind (recommended)

```bash
# Create cluster
kind create cluster --name argocd-lab

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/notifications丛/application.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/install.yaml

# Wait for ArgoCD server
kubectl rollout status deployment/argocd-server -n argocd

# Get password
PASSWORD=$(kubectl -n argocd get secrets argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Password: $PASSWORD"

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080
```

### Using minikube

```bash
minikube start
minikube addons enable ingress
minikube addons enable dashboard

# Install ArgoCD
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/install.yaml
```

## 4. Deploy Applications

```bash
# Login to ArgoCD CLI
argocd login localhost:8080 --username admin --password "$PASSWORD"

# Option A: App-of-Apps (deploys everything)
kubectl apply -f bootstrap/root-app.yaml

# Option B: Individual apps
kubectl apply -f apps/helm/nginx-helm-dev.yaml
kubectl apply -f apps/kustomize/nginx-kustomize-dev.yaml

# Option C: ApplicationSets
kubectl apply -f applicationsets/helm-appset.yaml
```

## 5. Verify Deployment

```bash
# Check applications
argocd app list

# Get app status
argocd app get nginx-helm-dev
argocd app get nginx-kustomize-dev

# Watch sync status
argocd app wait nginx-helm-dev --timeout 300

# Check pods
kubectl get pods -A | grep nginx

# Check services
kubectl get svc -A | grep nginx

# View logs
kubectl logs -n nginx-helm-dev deploy/nginx-helm-dev -f
```

## 6. Test Sync Policies

```bash
# Dev - should auto-sync
argocd app sync nginx-helm-dev
# Check: pod should auto-heal after manual changes

# Prod - requires manual sync
argocd app sync nginx-helm-prod
# Verify: no auto-sync behavior

# Test rollback
argocd app history nginx-helm-prod
argocd app rollback nginx-helm-prod <revision-id>
```

## 7. Test Production Hardening Features

```bash
# Check PodDisruptionBudget
kubectl get pdb -A

# Check ResourceQuota
kubectl get resourcequota -A

# Check LimitRange
kubectl get limitrange -A

# Check NetworkPolicy
kubectl get networkpolicy -A

# Check PriorityClass
kubectl get priorityclass | grep nginx

# Test graceful shutdown
kubectl delete pod -n nginx-helm-prod -l app.kubernetes.io/name=nginx
kubectl logs -n nginx-helm-prod <new-pod> | grep -i shutdown
```

## 8. Test Multi-Repo Pattern

```bash
# Add a mock microservice
./add-microservice.sh --single
# Service Name: test-service
# Repository URL: https://github.com/YOUR/test-service.git
# Path: deploy/helm
# Type: 1 (Helm)
# Environments: dev

# Verify external app created
ls apps/external/
cat apps/external/test-service-dev.yaml

# Generate ApplicationSet
./add-microservice.sh --appset
```

## 9. End-to-End GitOps Flow

```bash
# Make a change
echo "# Updated" >> helm-charts/nginx/values-dev.yaml

# Commit and push
git add -A
git commit -m "test: update dev values"
git push

# Watch ArgoCD sync (in another terminal)
watch argocd app get nginx-helm-dev

# Verify the change
kubectl get configmap -n nginx-helm-dev -o yaml | grep Updated
```

## 10. Cleanup

```bash
# Option A: Use teardown script
./scripts/teardown.sh

# Option B: Manual cleanup
kubectl delete -f bootstrap/root-app.yaml
kubectl delete -f applicationsets/

# Delete namespaces
kubectl delete namespace nginx-helm-dev nginx-helm-staging nginx-helm-prod
kubectl delete namespace nginx-kustomize-dev nginx-kustomize-staging nginx-kustomize-prod

# Delete kind cluster
kind delete cluster --name argocd-lab
```

## Quick Test Command

```bash
# One-liner for quick validation
helm template test helm-charts/nginx -f helm-charts/nginx/values-prod.yaml | kubectl apply --dry-run=server -f - && \
kustomize build kustomize/nginx/overlays/prod | kubectl apply --dry-run=server -f - && \
echo "✓ All validations passed"
```
