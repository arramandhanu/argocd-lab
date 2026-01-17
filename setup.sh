#!/bin/bash
# setup.sh - Configure ArgoCD Lab for your environment
# Supports: GitHub, GitLab, Bitbucket, Azure DevOps, or any Git provider
# Usage: ./setup.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          ArgoCD App-of-Apps Lab - Setup Script            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Select Git provider
echo -e "${YELLOW}Select your Git provider:${NC}"
echo ""
echo "  1) GitHub"
echo "  2) GitLab"
echo "  3) Bitbucket"
echo "  4) Azure DevOps"
echo "  5) Custom URL (any provider)"
echo ""
read -p "Enter choice [1-5]: " PROVIDER_CHOICE

case $PROVIDER_CHOICE in
    1)
        PROVIDER="github"
        read -p "GitHub Username or Org: " GIT_USER
        read -p "Repository Name [argocd-lab]: " REPO_NAME
        REPO_NAME=${REPO_NAME:-argocd-lab}
        REPO_URL="https://github.com/${GIT_USER}/${REPO_NAME}.git"
        ;;
    2)
        PROVIDER="gitlab"
        read -p "GitLab Username or Group: " GIT_USER
        read -p "Repository Name [argocd-lab]: " REPO_NAME
        REPO_NAME=${REPO_NAME:-argocd-lab}
        read -p "GitLab Instance [gitlab.com]: " GITLAB_HOST
        GITLAB_HOST=${GITLAB_HOST:-gitlab.com}
        REPO_URL="https://${GITLAB_HOST}/${GIT_USER}/${REPO_NAME}.git"
        ;;
    3)
        PROVIDER="bitbucket"
        read -p "Bitbucket Workspace: " GIT_USER
        read -p "Repository Name [argocd-lab]: " REPO_NAME
        REPO_NAME=${REPO_NAME:-argocd-lab}
        REPO_URL="https://bitbucket.org/${GIT_USER}/${REPO_NAME}.git"
        ;;
    4)
        PROVIDER="azure"
        read -p "Azure DevOps Organization: " AZURE_ORG
        read -p "Project Name: " AZURE_PROJECT
        read -p "Repository Name [argocd-lab]: " REPO_NAME
        REPO_NAME=${REPO_NAME:-argocd-lab}
        GIT_USER="${AZURE_ORG}/${AZURE_PROJECT}"
        REPO_URL="https://dev.azure.com/${AZURE_ORG}/${AZURE_PROJECT}/_git/${REPO_NAME}"
        ;;
    5)
        PROVIDER="custom"
        echo -e "${CYAN}Enter your full Git repository URL${NC}"
        echo "Examples:"
        echo "  - https://github.com/user/repo.git"
        echo "  - https://gitlab.example.com/group/repo.git"
        echo "  - git@github.com:user/repo.git"
        echo ""
        read -p "Repository URL: " REPO_URL
        GIT_USER="custom"
        REPO_NAME="custom"
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

echo ""
read -p "Git Branch [main]: " GIT_BRANCH
GIT_BRANCH=${GIT_BRANCH:-main}

read -p "ArgoCD Namespace [argocd]: " ARGOCD_NS
ARGOCD_NS=${ARGOCD_NS:-argocd}

# Summary
echo ""
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Configuration Summary${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "  Provider:        ${GREEN}${PROVIDER}${NC}"
echo -e "  Repository URL:  ${GREEN}${REPO_URL}${NC}"
echo -e "  Branch:          ${GREEN}${GIT_BRANCH}${NC}"
echo -e "  ArgoCD NS:       ${GREEN}${ARGOCD_NS}${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

read -p "Proceed with these settings? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-Y}

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Setup cancelled.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Updating manifests...${NC}"

# Count files to update
FILE_COUNT=$(find . -type f -name "*.yaml" -not -path "./.git/*" | wc -l | tr -d ' ')
echo -e "  Found ${CYAN}${FILE_COUNT}${NC} YAML files to update"

# Find and replace in all YAML files
find . -type f -name "*.yaml" -not -path "./.git/*" | while read file; do
    # Replace repo URL (handle both with and without .git suffix)
    sed -i.bak "s|https://github.com/arramandhanu/argocd-lab.git|${REPO_URL}|g" "$file"
    sed -i.bak "s|https://github.com/arramandhanu/argocd-lab|${REPO_URL%.git}|g" "$file"
    
    # Replace branch
    sed -i.bak "s|targetRevision: main|targetRevision: ${GIT_BRANCH}|g" "$file"
    
    # Replace argocd namespace if different
    if [ "$ARGOCD_NS" != "argocd" ]; then
        sed -i.bak "s|namespace: argocd|namespace: ${ARGOCD_NS}|g" "$file"
    fi
    
    # Remove backup files
    rm -f "${file}.bak"
done

# Update Chart.yaml maintainer info
if [ "$GIT_USER" != "custom" ]; then
    find . -type f -name "Chart.yaml" | while read file; do
        sed -i.bak "s|arramandhanu|${GIT_USER}|g" "$file"
        rm -f "${file}.bak"
    done
fi

echo -e "  ${GREEN}✓${NC} Updated all repository URLs"
echo -e "  ${GREEN}✓${NC} Updated branch references"
if [ "$ARGOCD_NS" != "argocd" ]; then
    echo -e "  ${GREEN}✓${NC} Updated ArgoCD namespace"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "  1. Review changes:"
echo -e "     ${CYAN}git diff${NC}"
echo ""
echo "  2. Commit and push:"
echo -e "     ${CYAN}git add -A && git commit -m 'Configure ArgoCD lab' && git push${NC}"
echo ""
echo "  3. Deploy root application:"
echo -e "     ${CYAN}kubectl apply -f bootstrap/root-app.yaml${NC}"
echo ""
echo "  Or use ApplicationSets:"
echo -e "     ${CYAN}kubectl apply -f applicationsets/helm-appset.yaml${NC}"
echo -e "     ${CYAN}kubectl apply -f applicationsets/kustomize-appset.yaml${NC}"
echo ""
