#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace hermes --dry-run=client -o yaml | kubectl apply -f -

kubectl -n hermes apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hermes-stable
spec:
  replicas: 4
  selector:
    matchLabels: {app: hermes, track: stable}
  template:
    metadata:
      labels: {app: hermes, track: stable}
    spec:
      containers:
        - name: nginx
          image: nginx:1.30-alpine
          resources: {requests: {cpu: 10m, memory: 16Mi}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hermes-canary
spec:
  replicas: 0
  selector:
    matchLabels: {app: hermes, track: canary}
  template:
    metadata:
      labels: {app: hermes, track: canary}
    spec:
      containers:
        - name: nginx
          image: nginx:1.30-alpine
          resources: {requests: {cpu: 10m, memory: 16Mi}}
---
apiVersion: v1
kind: Service
metadata:
  name: hermes-svc
spec:
  selector:
    app: hermes
  ports:
    - port: 80
      targetPort: 80
EOF

echo "READY q04"
