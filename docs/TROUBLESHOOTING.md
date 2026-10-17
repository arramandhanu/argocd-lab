# Troubleshooting Guide

Common issues and solutions for ArgoCD App-of-Apps Lab.

## Sync Failures

### Application stuck in OutOfSync
```bash
# Check application status
argocd app get <app-name>

# View sync diff
argocd app diff <app-name>

# View events
kubectl describe application <app-name> -n argocd
```

### Image pull errors
```bash
# Verify image exists
kubectl run test --image=nginx:1.25.3-alpine

# Check image pull secrets
kubectl get pods -A | grep ErrImagePull
```

### Resource conflicts
```bash
# Check existing resources
kubectl get all -n <namespace>

# Delete stuck resources
kubectl delete pod <pod-name> -n <namespace> --force
```

## Helm Issues

### Template errors
```bash
# Debug template
helm template test helm-charts/nginx -f helm-charts/nginx/values-dev.yaml --debug

# Check values
helm show values helm-charts/nginx
```

### Release not found
```bash
# List releases
helm list -A

# Uninstall stuck release
helm uninstall <release> -n <namespace>
```

## Kustomize Issues

### Patch conflicts
```bash
# Debug build
kustomize build kustomize/nginx/overlays/dev --debug

# Validate resources
kustomize build kustomize/nginx/overlays/dev | kubectl apply --dry-run=server -f -
```

## ArgoCD Problems

### ArgoCD not responding
```bash
# Check pod status
kubectl get pods -n argocd

# Check logs
kubectl logs -n argocd deployment/argocd-server

# Restart if needed
kubectl rollout restart deployment/argocd-server -n argocd
```

### Application controller issues
```bash
# Check controller logs
kubectl logs -n argocd statefulset/argocd-application-controller

# Check resource health
kubectl get application -n argocd -o wide
```

## Permission Denied

### AppProject restrictions
```bash
# Check AppProject
argocd app get <app-name>

# Verify destination matches project
kubectl get appproject <project-name> -n argocd -o yaml
```

## Debug Mode

Enable detailed logging:
```bash
kubectl edit configmap argocd-cmd-params-cm -n argocd
# Set server.log.level: debug
```
