# External Secrets Example

This directory demonstrates External Secrets Operator (ESO) integration.

## Setup

1. Install ESO:
```bash
kubectl apply -k "github.com/external-secrets/external-secrets/releases/download/cloudsave-0.9.0/external-secrets.yaml"
```

2. Create a SecretStore (AWS Secrets Manager example):
```bash
kubectl apply -f secretstore-aws.yaml
```

## Usage

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: nginx-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: nginx-secrets
    creationPolicy: Owner
  data:
    - secretKey: API_KEY
      remoteRef:
        key: production/nginx/api-key
    - secretKey: DATABASE_URL
      remoteRef:
        key: production/nginx/database-url
```

## Generate from Existing Secrets

```bash
# For AWS
esoctl create secret --store-name aws-secrets-manager --secret-name prod/nginx/config nginx-helm-dev

# For Vault
esoctl create secret --store-name vault-backend --secret-name prod/nginx/config nginx-helm-dev
```
