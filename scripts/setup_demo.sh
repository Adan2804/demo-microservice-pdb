#!/bin/bash

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Checking Minikube status...${NC}"
minikube status

echo -e "${GREEN}Checking ArgoCD status...${NC}"
kubectl get pods -n argocd

echo -e "${GREEN}Getting ArgoCD Password...${NC}"
argocd_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Password: $argocd_password"

echo -e "${GREEN}Building Docker Image v1...${NC}"
eval $(minikube docker-env)
# Build v1
docker build -t demo-pdb:v1 --build-arg APP_VERSION=v1 ./app

echo -e "${GREEN}Building Docker Image v2...${NC}"
# Build v2 (Simulating a change by just tagging differently, but in real life we would change code or env)
# For this demo, we will rely on the Deployment ENV var to change the version displayed, 
# but we build a v2 tag to simulate a new image release.
docker build -t demo-pdb:v2 ./app

echo -e "${GREEN}Setup Complete!${NC}"
echo "You can now login to ArgoCD at https://localhost:8080 (forward port first) with username 'admin' and the password above."
