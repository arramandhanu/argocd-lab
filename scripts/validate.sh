#!/bin/bash
# validate.sh - Pre-deployment validation script
# Checks prerequisites and validates manifests

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

check() {
    if command -v "$1" &> /dev/null; then
        VERSION=$($1 version --client 2>/dev/null | head -1 || echo "installed")
        echo -e "${GREEN}✓${NC} $1: $VERSION"
    else
        echo -e "${RED}✗${NC} $1: not found"
        ((ERRORS++))
    fi
}

echo "=== Prerequisite Checks ==="
check kubectl
check helm
check kustomize
check argocd

echo ""
echo "=== YAML Validation ==="
# Check if pyyaml is installed
if python3 -c "import yaml" 2>/dev/null; then
    for f in $(find . -name "*.yaml" -not -path "./.git/*" -not -path "./.github/*" -not -path "./helm-charts/*/templates/*" -not -path "./policies/helm/*"); do
        if python3 -c "import yaml; list(yaml.safe_load_all(open('$f')))" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $f"
        else
            echo -e "${RED}✗${NC} $f - Invalid YAML"
            ((ERRORS++))
        fi
    done
else
    echo -e "${YELLOW}⚠${NC} Skipping YAML validation (pyyaml not installed)"
    echo "  Install with: pip3 install pyyaml"
fi

echo ""
echo "=== Helm Chart Validation ==="
if helm lint helm-charts/nginx 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Helm chart valid"
else
    echo -e "${RED}✗${NC} Helm chart has errors"
    ((ERRORS++))
fi

echo ""
echo "=== Kustomize Build Validation ==="
for env in dev staging prod; do
    if kustomize build kustomize/nginx/overlays/$env > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} kustomize/$env build OK"
    else
        echo -e "${RED}✗${NC} kustomize/$env build failed"
        ((ERRORS++))
    fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}All validations passed!${NC}"
    exit 0
else
    echo -e "${RED}Found $ERRORS errors${NC}"
    exit 1
fi
