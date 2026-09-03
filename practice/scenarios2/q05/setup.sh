#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace apollo --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apollo create serviceaccount apollo-reader --dry-run=client -o yaml | kubectl apply -f -
kubectl -n apollo delete role apollo-pod-reader --ignore-not-found
kubectl -n apollo delete rolebinding apollo-pod-reader-binding --ignore-not-found

# a pod to make "list pods" meaningful
kubectl -n apollo apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: apollo-sample
spec:
  containers:
    - name: nginx
      image: nginx:1-alpine
      resources: {requests: {cpu: 10m, memory: 16Mi}}
EOF

echo "READY q05"
