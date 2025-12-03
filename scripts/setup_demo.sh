#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 SETTING UP DEMO MICROSERVICE (PDB + ARGOCD)${NC}"
echo "=================================================="

# 1. Checks
echo -e "${GREEN}Checking Minikube status...${NC}"
if ! minikube status > /dev/null 2>&1; then
    echo -e "${RED}Minikube is not running!${NC}"
    exit 1
fi

echo -e "${GREEN}Checking ArgoCD status...${NC}"
if ! kubectl get namespace argocd > /dev/null 2>&1; then
    echo -e "${YELLOW}ArgoCD is not installed. Installing...${NC}"
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo -e "${GREEN}Waiting for ArgoCD to be ready...${NC}"
    kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
    
    echo -e "${GREEN}ArgoCD installed successfully!${NC}"
else
    echo -e "${GREEN}ArgoCD is already installed.${NC}"
fi

# 2. Get Password
echo -e "${GREEN}Getting ArgoCD Password...${NC}"
SECRET_NAME="argocd-initial-admin-secret"
if kubectl -n argocd get secret $SECRET_NAME > /dev/null 2>&1; then
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret $SECRET_NAME -o jsonpath="{.data.password}" | base64 -d)
else
    echo -e "${RED}Initial admin secret not found.${NC}"
    ARGOCD_PASSWORD="<MANUAL_INPUT_REQUIRED>"
fi

# 3. Build Images
echo -e "${GREEN}Building Docker Image v1...${NC}"
eval $(minikube docker-env)
docker build -t demo-pdb:v1 --build-arg APP_VERSION=v1 ./app

echo -e "${GREEN}Building Docker Image v2...${NC}"
docker build -t demo-pdb:v2 --build-arg APP_VERSION=v2 ./app

# 4. Deploy ArgoCD App
echo -e "${GREEN}Deploying ArgoCD Application...${NC}"
APP_YAML="./argocd/application.yaml"
if [ -f "$APP_YAML" ]; then
    kubectl apply -f "$APP_YAML" -n argocd
    echo "Waiting for application to be created..."
    sleep 5
    # Force sync
    kubectl patch application demo-microservice-pdb -n argocd --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}' 2>/dev/null || true
else
    echo -e "${RED}Application manifest not found at $APP_YAML${NC}"
fi

# 5. Port Forwards
echo -e "${GREEN}Configuring Port-Forwards...${NC}"

# Kill existing
pkill -f "kubectl port-forward.*argocd-server" 2>/dev/null || true
pkill -f "kubectl port-forward.*demo-pdb-service" 2>/dev/null || true

# ArgoCD
echo "Starting ArgoCD Port-Forward (8081:443)..."
kubectl port-forward svc/argocd-server -n argocd 8081:443 > /dev/null 2>&1 &
ARGOCD_PID=$!
sleep 3

# App (Wait for it to be ready if deployed, otherwise skip)
MICRO_PID=""
if kubectl get svc demo-pdb-service > /dev/null 2>&1; then
    echo "Starting App Port-Forward (8082:80)..."
    kubectl port-forward svc/demo-pdb-service 8082:80 > /dev/null 2>&1 &
    MICRO_PID=$!
fi

# 5. Summary
echo ""
echo -e "${GREEN}✅ SETUP COMPLETE!${NC}"
echo "=================================================="
echo -e "🔑 ArgoCD User: ${BLUE}admin${NC}"
echo -e "🔑 ArgoCD Pass: ${BLUE}$ARGOCD_PASSWORD${NC}"
echo -e "🌐 ArgoCD URL:  ${BLUE}https://localhost:8081${NC}"
echo "--------------------------------------------------"
if [ -n "$MICRO_PID" ]; then
    echo -e "🌐 App URL:     ${BLUE}http://localhost:8082/public/hello${NC}"
else
    echo -e "⚠️  App not yet deployed. Run 'kubectl apply' or sync in ArgoCD."
    echo "   Then run: kubectl port-forward svc/demo-pdb-service 8082:80"
fi
echo "--------------------------------------------------"
echo "Background PIDs: ArgoCD=$ARGOCD_PID App=$MICRO_PID"
echo "To stop port-forwards run: pkill -f 'kubectl port-forward'"

kubectl apply -f ./argocd/application.yaml -n argocd