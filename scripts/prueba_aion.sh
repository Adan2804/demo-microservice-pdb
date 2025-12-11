#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'

echo -e "${GREEN}🚀 AION FLUX DAILY SETUP${NC}"
echo "========================================"

echo -e "${GREEN}Checking Minikube...${NC}"
minikube status > /dev/null 2>&1 || { echo -e "${RED}Minikube not running${NC}"; exit 1; }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
AION_FLUX_DIR="${SCRIPT_DIR}/../../aion-flux"
CHART_DIR="${AION_FLUX_DIR}/charts/aion-flux-operator"
EXAMPLE_YAML="${AION_FLUX_DIR}/examples/aionrollout-demo.yaml"

echo -e "${GREEN}Using Minikube Docker daemon...${NC}"
eval $(minikube docker-env)

echo -e "${GREEN}Building AION FLUX Operator image...${NC}"
docker build -t aion-flux:dev "${AION_FLUX_DIR}"

echo -e "${GREEN}Installing/Upgrading Helm chart...${NC}"
helm upgrade --install aion-flux-operator "${CHART_DIR}" \
  -n aion --create-namespace \
  --set image.repository=aion-flux \
  --set image.tag=dev \
  --set namespace=default

echo -e "${GREEN}Waiting for operator pod...${NC}"
kubectl -n aion rollout status deploy/aion-flux-operator --timeout=180s

echo -e "${GREEN}Applying AionRollout demo...${NC}"
kubectl apply -f "${EXAMPLE_YAML}" -n default

if kubectl -n default get deploy demo-pdb-deployment-v2-shadow > /dev/null 2>&1; then
  echo -e "${GREEN}Waiting for shadow deployment...${NC}"
  kubectl -n default rollout status deploy/demo-pdb-deployment-v2-shadow --timeout=180s || true
fi

echo -e "${GREEN}✅ DONE${NC}"
kubectl -n default get deploy,svc,pods -o wide | sed -n '1,200p'

echo -e "${GREEN}Istio routing check...${NC}"
if ! kubectl api-resources --api-group=networking.istio.io > /dev/null 2>&1; then
  echo -e "${GREEN}Enabling Minikube Istio addon...${NC}"
  minikube addons enable istio > /dev/null 2>&1 || true
fi
kubectl apply -f "${SCRIPT_DIR}/../k8s/istio-routing.yaml" -n default
kubectl -n default get gateway,virtualservice || true

echo -e "${GREEN}Enabling sidecar injection on default namespace...${NC}"
kubectl label namespace default istio-injection=enabled --overwrite > /dev/null 2>&1 || true
echo -e "${GREEN}Restarting deployments for sidecar injection...${NC}"
kubectl -n default rollout restart deploy/demo-pdb-deployment || true
kubectl -n default rollout restart deploy/demo-pdb-deployment-v2-shadow || true
kubectl -n default rollout status deploy/demo-pdb-deployment --timeout=180s || true
kubectl -n default rollout status deploy/demo-pdb-deployment-v2-shadow --timeout=180s || true

echo -e "${GREEN}Ensuring Istio IngressGateway...${NC}"
if ! kubectl -n istio-system get svc istio-ingressgateway > /dev/null 2>&1; then
  curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.21.0 sh -
  export PATH="$PWD/istio-1.21.0/bin:$PATH"
  istioctl install -y --set profile=demo
fi
kubectl -n istio-system rollout status deploy/istio-ingressgateway --timeout=300s || true

echo -e "${GREEN}Access info:${NC}"
MINI_IP=$(minikube ip)
echo "Main via NodePort: http://$MINI_IP:30080/public/hello"

# Prefer LoadBalancer IP (requires 'minikube tunnel' running). Fallback to local port-forward.
LB_IP=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
if [ -n "$LB_IP" ]; then
  echo "Ingress URL (LB): http://$LB_IP/"
  echo "Test main:   curl http://$LB_IP/public/hello"
  echo "Test shadow: curl -H 'x-aion-version: v2' http://$LB_IP/public/hello"
else
  echo "No LoadBalancer IP detected. Starting local port-forward on 8080..."
  kubectl -n istio-system port-forward svc/istio-ingressgateway 8080:80 > /dev/null 2>&1 &
  PF_PID=$!
  echo "Port-forward started on http://localhost:8080 (PID $PF_PID)"
  echo "Test main:   curl http://localhost:8080/public/hello"
  echo "Test shadow: curl -H 'x-aion-version: v2' http://localhost:8080/public/hello"
  echo "Tip: run 'minikube tunnel' in a separate terminal to get a stable LoadBalancer IP."
fi

echo -e "${GREEN}Enabling NGINX Ingress (alternative header routing)...${NC}"
minikube addons enable ingress > /dev/null 2>&1 || true
kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=240s || true
for i in {1..20}; do
  if kubectl -n ingress-nginx get svc ingress-nginx-controller-admission > /dev/null 2>&1; then
    break
  fi
  sleep 5
done
kubectl apply -f "${SCRIPT_DIR}/../k8s/nginx-ingress.yaml" -n default
echo "Use single URL with Host header:"
echo "curl -H 'Host: aion.local' http://$(minikube ip)/public/hello"
echo "curl -H 'Host: aion.local' -H 'x-aion-version: v2' http://$(minikube ip)/public/hello"
