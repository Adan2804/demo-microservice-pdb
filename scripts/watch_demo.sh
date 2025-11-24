#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Getting Service URL...${NC}"
# This command gets the URL for the service (works for NodePort/LoadBalancer/ClusterIP with tunnel)
SERVICE_URL=$(minikube service demo-pdb-service --url | head -n 1)

if [ -z "$SERVICE_URL" ]; then
  echo -e "${RED}Could not get service URL. Is the service deployed?${NC}"
  echo "Try running: minikube service demo-pdb-service --url"
  exit 1
fi

echo -e "${GREEN}Monitoring Service at $SERVICE_URL${NC}"

while true; do
  RESPONSE=$(curl -s $SERVICE_URL/public/hello)
  echo -e "${BLUE}[$(date +%T)] Response:${NC} $RESPONSE"
  sleep 1
done
