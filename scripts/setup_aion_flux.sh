#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${GREEN}🚀 AION FLUX DAILY SETUP${NC}"
echo "========================================"

echo -e "${GREEN}Checking Minikube...${NC}"
minikube status > /dev/null 2>&1 || { echo -e "${RED}Minikube not running${NC}"; exit 1; }

echo -e "${GREEN}Using Minikube Docker daemon...${NC}"
eval $(minikube docker-env)

echo -e "${GREEN}Building AION FLUX Operator image...${NC}"
docker build -t aion-flux:dev ./../../aion-flux

echo -e "${GREEN}Installing/Upgrading Helm chart...${NC}"
helm upgrade --install aion-flux-operator ./../../aion-flux/charts/aion-flux-operator \
  -n aion --create-namespace \
  --set image.repository=aion-flux \
  --set image.tag=dev \
  --set namespace=default

echo -e "${GREEN}Waiting for operator pod...${NC}"
kubectl -n aion rollout status deploy/aion-flux-operator --timeout=180s

echo -e "${GREEN}Applying AionRollout demo...${NC}"
kubectl apply -f ./../../aion-flux/examples/aionrollout-demo.yaml -n default

echo -e "${GREEN}Waiting for shadow deployment...${NC}"
kubectl -n default rollout status deploy/demo-pdb-deployment-v2-shadow --timeout=180s || true

echo -e "${GREEN}✅ DONE${NC}"
kubectl -n default get deploy,svc,pods -o wide | sed -n '1,200p'

