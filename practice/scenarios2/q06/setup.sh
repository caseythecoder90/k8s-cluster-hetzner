#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace artemis --dry-run=client -o yaml | kubectl apply -f -
kubectl -n artemis delete deployment artemis-api --ignore-not-found
sleep 1

# revision 1: working
kubectl -n artemis apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: artemis-api
spec:
  replicas: 2
  selector:
    matchLabels: {app: artemis-api}
  template:
    metadata:
      labels: {app: artemis-api}
    spec:
      containers:
        - name: api
          image: nginx:1.30-alpine
          resources: {requests: {cpu: 10m, memory: 16Mi}}
EOF
kubectl -n artemis rollout status deploy/artemis-api --timeout=60s >/dev/null

# revision 2: broken image (typo'd tag), current live state
kubectl -n artemis set image deploy/artemis-api api=nginx:1.30-alpine-typo >/dev/null

echo "READY q06 — Pods are currently broken (that's the point)"
