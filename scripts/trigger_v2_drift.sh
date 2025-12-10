#!/bin/bash
set -euo pipefail
echo "Triggering v2 image drift on demo-pdb-deployment..."
kubectl -n default set image deployment/demo-pdb-deployment demo-pdb-container=demo-pdb:v2
kubectl -n default rollout status deployment/demo-pdb-deployment --timeout=120s || true
echo "Operator should revert to v1 and create shadow with v2. Check resources:"
kubectl -n default get deploy,svc,pods -o wide | sed -n '1,200p'
