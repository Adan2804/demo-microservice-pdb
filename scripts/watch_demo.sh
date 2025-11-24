#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVICE_URL=$(minikube service demo-pdb-service --url)
echo -e "${GREEN}Monitoring Service at $SERVICE_URL${NC}"

while true; do
  RESPONSE=$(curl -s $SERVICE_URL/public/hello)
  echo -e "${BLUE}[$(date +%T)] Response:${NC} $RESPONSE"
  sleep 1
done
