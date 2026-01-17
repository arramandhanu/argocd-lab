# Sync Policies Guide

This guide explains how to configure different sync behaviors per environment.

## Sync Policy Overview

| Environment | Auto Sync | Self Heal | Trigger |
|-------------|-----------|-----------|---------|
| **Dev** | ✅ Yes | ✅ Yes | Automatic on merge |
| **Staging** | ✅ Yes | ✅ Yes | Automatic on merge |
| **Prod** | ❌ No | ❌ No | Manual only |

## How It Works

### Dev & Staging (Auto Sync)

```yaml
syncPolicy:
  automated:
    prune: true      # Remove resources deleted from Git
    selfHeal: true   # Revert manual changes to match Git
  syncOptions:
    - CreateNamespace=true
```

**Behavior:**
- Merge to main → ArgoCD detects change → Auto deploys within 3 minutes
- Manual kubectl changes → ArgoCD reverts them automatically

### Production (Manual Sync)

```yaml
syncPolicy:
  # No 'automated' block = manual sync only
  syncOptions:
    - CreateNamespace=true
    - PruneLast=true          # Prune after all resources sync
    - ApplyOutOfSyncOnly=true # Only apply changed resources
```

**Behavior:**
- Merge to main → ArgoCD shows "OutOfSync" status
- Requires manual trigger to deploy

## Triggering Production Sync

### Option 1: ArgoCD UI

1. Open ArgoCD dashboard
2. Find the prod application
3. Click **"Sync"** button
4. Review changes → **"Synchronize"**

### Option 2: CLI

```bash
# Sync a single app
argocd app sync nginx-helm-prod

# Sync with prune
argocd app sync nginx-helm-prod --prune

# Dry run first
argocd app sync nginx-helm-prod --dry-run
```

### Option 3: CI/CD Pipeline (Approved Merge)

Add to your CI/CD (GitHub Actions example):

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
    paths:
      - 'helm-charts/nginx/values-prod.yaml'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # Requires approval in GitHub
    steps:
      - name: Trigger ArgoCD Sync
        run: |
          argocd app sync nginx-helm-prod \
            --server $ARGOCD_SERVER \
            --auth-token $ARGOCD_TOKEN \
            --grpc-web
```

## Sync Windows (Optional)

Restrict prod syncs to maintenance windows:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-helm-prod
spec:
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
  # Only allow sync during weekdays 2-4 AM UTC
  syncWindows:
    - kind: allow
      schedule: '0 2 * * 1-5'
      duration: 2h
      applications:
        - '*-prod'
    - kind: deny
      schedule: '* * * * *'  # Deny all other times
      applications:
        - '*-prod'
```

## Rollback

If something goes wrong in production:

```bash
# View history
argocd app history nginx-helm-prod

# Rollback to previous version
argocd app rollback nginx-helm-prod <revision-id>

# Or sync to specific Git commit
argocd app sync nginx-helm-prod --revision <commit-sha>
```

## Best Practices

1. **Never auto-sync prod**: Use manual or pipeline-triggered sync
2. **Require approvals**: Use GitHub Environments or similar
3. **Sync windows**: Limit prod changes to maintenance hours
4. **Dry run first**: Always preview changes before applying
5. **Notifications**: Set up Slack/Teams alerts for prod syncs
