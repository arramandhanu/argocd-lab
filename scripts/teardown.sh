#!/bin/bash
# teardown.sh - Clean up all ArgoCD resources

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NAMESPACE="${1:-argocd}"

echo -e "${YELLOW}Teardown ArgoCD Lab Resources${NC}"
echo "Namespace: $NAMESPACE"
echo ""

read -p "This will delete ALL ArgoCD Applications. Continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Deleting ApplicationSets..."
kubectl delete applicationsets -n "$NAMESPACE" --all 2>/dev/null || true

echo "Deleting Applications..."
kubectl delete applications -n "$NAMESPACE" --all 2>/dev/null || true

echo "Deleting AppProjects..."
kubectl delete appprojects -n "$NAMESPACE" --all 2>/dev/null || true

echo ""
echo "Namespaces to clean (optional):"
echo "  kubectl delete namespace nginx-helm-dev nginx-helm-staging nginx-helm-prod"
echo "  kubectl delete namespace nginx-kustomize-dev nginx-kustomize-staging nginx-kustomize-prod"

echo ""
echo -e "${GREEN}Teardown complete!${NC}"
