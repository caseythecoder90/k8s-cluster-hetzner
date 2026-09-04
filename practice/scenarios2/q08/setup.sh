#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace hades --dry-run=client -o yaml | kubectl apply -f -
kubectl -n hades delete deployment hades-cache --ignore-not-found

kubectl -n hades apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hades-cache
spec:
  replicas: 1
  selector:
    matchLabels: {app: hades-cache}
  template:
    metadata:
      labels: {app: hades-cache}
    spec:
      containers:
        - name: cache
          image: busybox:1
          command: ["/bin/sh", "-c"]
          args: ["sleep 8 && touch /tmp/ready && sleep 3600"]
          resources: {requests: {cpu: 10m, memory: 16Mi}}
---
apiVersion: v1
kind: Service
metadata:
  name: hades-cache-svc
spec:
  selector:
    app: hades-cache
  ports:
    - port: 80
      targetPort: 80
EOF

echo "READY q08"
