#!/bin/bash
# add-microservice.sh - Generate ArgoCD Application manifests for external microservices
# This script reads from config/microservices.conf and generates Application YAMLs
#
# Usage:
#   ./add-microservice.sh                    # Generate from config file
#   ./add-microservice.sh --single           # Interactive mode for one service
#   ./add-microservice.sh --appset           # Generate ApplicationSet instead

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/microservices.conf"
OUTPUT_DIR="${SCRIPT_DIR}/apps/external"
ARGOCD_NS="argocd"

# Parse arguments
MODE="batch"
if [ "$1" == "--single" ]; then
    MODE="single"
elif [ "$1" == "--appset" ]; then
    MODE="appset"
fi

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║       ArgoCD Microservice Application Generator           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

generate_app() {
    local NAME=$1
    local REPO_URL=$2
    local PATH=$3
    local TYPE=$4
    local ENV=$5
    local BRANCH=${6:-main}

    local NAMESPACE="${NAME}-${ENV}"
    local APP_NAME="${NAME}-${ENV}"
    local OUTPUT_FILE="${OUTPUT_DIR}/${APP_NAME}.yaml"

    echo -e "  Generating: ${CYAN}${APP_NAME}${NC}"

    if [ "$TYPE" == "helm" ]; then
        # Determine sync policy based on environment
        if [ "$ENV" == "prod" ] || [ "$ENV" == "production" ]; then
            SYNC_POLICY="    # PRODUCTION: Manual sync only
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true"
        else
            SYNC_POLICY="    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true"
        fi

        cat > "$OUTPUT_FILE" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${APP_NAME}
  namespace: ${ARGOCD_NS}
  labels:
    app.kubernetes.io/name: ${NAME}
    app.kubernetes.io/instance: ${APP_NAME}
    environment: ${ENV}
    managed-by: argocd-lab
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${BRANCH}
    path: ${PATH}
    helm:
      valueFiles:
        - values-${ENV}.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: ${NAMESPACE}
  syncPolicy:
${SYNC_POLICY}
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF
    else
        # Kustomize - determine sync policy based on environment
        if [ "$ENV" == "prod" ] || [ "$ENV" == "production" ]; then
            SYNC_POLICY="    # PRODUCTION: Manual sync only
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true"
        else
            SYNC_POLICY="    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true"
        fi

        cat > "$OUTPUT_FILE" << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${APP_NAME}
  namespace: ${ARGOCD_NS}
  labels:
    app.kubernetes.io/name: ${NAME}
    app.kubernetes.io/instance: ${APP_NAME}
    environment: ${ENV}
    managed-by: argocd-lab
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${BRANCH}
    path: ${PATH}/${ENV}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${NAMESPACE}
  syncPolicy:
${SYNC_POLICY}
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF
    fi
}

generate_appset() {
    echo -e "${GREEN}Generating ApplicationSet from config...${NC}"
    echo ""

    local SERVICES=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        SERVICES+=("$line")
    done < "$CONFIG_FILE"

    if [ ${#SERVICES[@]} -eq 0 ]; then
        echo -e "${RED}No services found in config. Add services first.${NC}"
        exit 1
    fi

    local OUTPUT_FILE="${SCRIPT_DIR}/applicationsets/microservices-appset.yaml"

    cat > "$OUTPUT_FILE" << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: microservices
  namespace: argocd
spec:
  generators:
    - list:
        elements:
EOF

    for service in "${SERVICES[@]}"; do
        IFS='|' read -r NAME REPO_URL PATH TYPE ENVS BRANCH <<< "$service"
        BRANCH=${BRANCH:-main}
        
        IFS=',' read -ra ENV_ARRAY <<< "$ENVS"
        for ENV in "${ENV_ARRAY[@]}"; do
            cat >> "$OUTPUT_FILE" << EOF
          - name: ${NAME}
            env: ${ENV}
            repoURL: ${REPO_URL}
            path: ${PATH}
            type: ${TYPE}
            branch: ${BRANCH}
EOF
        done
    done

    cat >> "$OUTPUT_FILE" << 'EOF'
  template:
    metadata:
      name: '{{name}}-{{env}}'
      labels:
        app.kubernetes.io/name: '{{name}}'
        environment: '{{env}}'
        managed-by: argocd-lab
    spec:
      project: default
      source:
        repoURL: '{{repoURL}}'
        targetRevision: '{{branch}}'
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{name}}-{{env}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
EOF

    echo -e "${GREEN}✓${NC} Generated: ${CYAN}${OUTPUT_FILE}${NC}"
    echo ""
    echo -e "${YELLOW}Deploy with:${NC}"
    echo -e "  ${CYAN}kubectl apply -f ${OUTPUT_FILE}${NC}"
}

single_mode() {
    echo -e "${YELLOW}Add a single microservice${NC}"
    echo ""

    read -p "Service Name (e.g., user-service): " NAME
    read -p "Repository URL: " REPO_URL
    read -p "Path to manifests (e.g., deploy/helm): " PATH
    echo "Type: 1) Helm  2) Kustomize"
    read -p "Choice [1/2]: " TYPE_CHOICE
    TYPE="helm"
    [ "$TYPE_CHOICE" == "2" ] && TYPE="kustomize"
    read -p "Environments (comma-separated, e.g., dev,staging,prod): " ENVS
    read -p "Branch [main]: " BRANCH
    BRANCH=${BRANCH:-main}

    echo ""
    echo -e "${GREEN}Generating Application manifests...${NC}"

    IFS=',' read -ra ENV_ARRAY <<< "$ENVS"
    for ENV in "${ENV_ARRAY[@]}"; do
        generate_app "$NAME" "$REPO_URL" "$PATH" "$TYPE" "$ENV" "$BRANCH"
    done

    # Add to config
    echo "${NAME}|${REPO_URL}|${PATH}|${TYPE}|${ENVS}|${BRANCH}" >> "$CONFIG_FILE"

    echo ""
    echo -e "${GREEN}✓${NC} Generated ${#ENV_ARRAY[@]} Application manifests in ${CYAN}apps/external/${NC}"
    echo -e "${GREEN}✓${NC} Added to ${CYAN}config/microservices.conf${NC}"
}

batch_mode() {
    echo -e "${GREEN}Generating from config/microservices.conf...${NC}"
    echo ""

    local COUNT=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        IFS='|' read -r NAME REPO_URL PATH TYPE ENVS BRANCH <<< "$line"
        BRANCH=${BRANCH:-main}

        IFS=',' read -ra ENV_ARRAY <<< "$ENVS"
        for ENV in "${ENV_ARRAY[@]}"; do
            generate_app "$NAME" "$REPO_URL" "$PATH" "$TYPE" "$ENV" "$BRANCH"
            ((COUNT++))
        done
    done < "$CONFIG_FILE"

    if [ $COUNT -eq 0 ]; then
        echo -e "${YELLOW}No services found in config.${NC}"
        echo ""
        echo "Add services to config/microservices.conf or use:"
        echo -e "  ${CYAN}./add-microservice.sh --single${NC}"
    else
        echo ""
        echo -e "${GREEN}✓${NC} Generated ${CYAN}${COUNT}${NC} Application manifests"
    fi
}

# Main
case $MODE in
    single)
        single_mode
        ;;
    appset)
        generate_appset
        ;;
    batch)
        batch_mode
        ;;
esac

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Review generated files in apps/external/"
echo "  2. Commit and push changes"
echo "  3. Apply: kubectl apply -f apps/external/"
echo ""
