#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace demeter --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace demeter-other --dry-run=client -o yaml | kubectl apply -f -
kubectl -n demeter delete networkpolicy demeter-backend-policy --ignore-not-found

kubectl -n demeter apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demeter-backend
spec:
  replicas: 1
  selector:
    matchLabels: {app: backend}
  template:
    metadata:
      labels: {app: backend}
    spec:
      containers:
        - name: nginx
          image: nginx:1-alpine
          resources: {requests: {cpu: 10m, memory: 16Mi}}
---
apiVersion: v1
kind: Service
metadata:
  name: demeter-backend-svc
spec:
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demeter-frontend
spec:
  replicas: 1
  selector:
    matchLabels: {app: frontend}
  template:
    metadata:
      labels: {app: frontend}
    spec:
      containers:
        - name: curl
          image: busybox:1
          command: ["sleep", "3600"]
          resources: {requests: {cpu: 10m, memory: 16Mi}}
EOF

kubectl -n demeter-other apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: demeter-other-client
  labels:
    app: unrelated
spec:
  containers:
    - name: curl
      image: busybox:1
      command: ["sleep", "3600"]
      resources: {requests: {cpu: 10m, memory: 16Mi}}
EOF

echo "READY q12"
