#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace atlas --dry-run=client -o yaml | kubectl apply -f -
kubectl -n atlas delete deployment atlas-web --ignore-not-found

# The "dependency" atlas-web should wait for: a tiny listener on 5432
kubectl -n atlas apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: atlas-db
spec:
  replicas: 1
  selector:
    matchLabels: {app: atlas-db}
  template:
    metadata:
      labels: {app: atlas-db}
    spec:
      containers:
        - name: db
          image: busybox:1
          # -lk: listen, keep accepting new connections. No -e handler needed —
          # nc -z (used by the initContainer) only tests that the port accepts
          # a connection, it never sends/reads data.
          command: ["nc", "-lk", "-p", "5432"]
          ports:
            - containerPort: 5432
          resources: {requests: {cpu: 10m, memory: 16Mi}}
---
apiVersion: v1
kind: Service
metadata:
  name: atlas-db-svc
spec:
  selector:
    app: atlas-db
  ports:
    - port: 5432
      targetPort: 5432
EOF

echo "READY q16"
