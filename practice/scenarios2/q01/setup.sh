#!/bin/bash
source "$(dirname "$0")/../common.sh"

for ns in myth-alpha myth-beta myth-gamma; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

for ns in myth-alpha myth-beta myth-gamma; do
  kubectl -n "$ns" apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${ns}-demo
  labels:
    tier: demo
spec:
  containers:
    - name: nginx
      image: nginx:1-alpine
      resources: {requests: {cpu: 10m, memory: 16Mi}}
EOF
done
# a decoy without the label, so a naive "get pods -A" would over-select
kubectl -n myth-alpha apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: myth-alpha-other
  labels:
    tier: not-demo
spec:
  containers:
    - name: nginx
      image: nginx:1-alpine
      resources: {requests: {cpu: 10m, memory: 16Mi}}
EOF

$SSH_CP "sudo mkdir -p /course2/1 && sudo chown deploy:deploy /course2/1 && rm -f /course2/1/demo-pods"
echo "READY q01 — solve on: $SSH_CP"
