#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe jordan
mkcourse $COURSE/6

# Not the webserver helper: this question needs one Pod listening on two
# different ports, so nginx is given two server blocks serving two pages.
kubectl apply -f - >/dev/null <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jordan-api
  namespace: jordan
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jordan-api
  template:
    metadata:
      labels:
        app: jordan-api
    spec:
      containers:
        - name: api
          image: nginx:1-alpine
          command:
            - /bin/sh
            - -c
            - |
              mkdir -p /usr/share/nginx/html /usr/share/nginx/admin
              echo jordan-api > /usr/share/nginx/html/index.html
              echo jordan-admin > /usr/share/nginx/admin/index.html
              printf 'server { listen 8080; root /usr/share/nginx/html; }\nserver { listen 9090; root /usr/share/nginx/admin; }\n' > /etc/nginx/conf.d/default.conf
              exec nginx -g 'daemon off;'
          ports:
            - name: api
              containerPort: 8080
            - name: admin
              containerPort: 9090
          resources:
            requests: {cpu: 5m, memory: 12Mi}
---
apiVersion: v1
kind: Service
metadata:
  name: jordan-api
  namespace: jordan
spec:
  type: ClusterIP
  selector:
    app: jordan-api
  ports:
    - name: api
      port: 80
      targetPort: 8080
    - name: admin
      port: 9090
      targetPort: 9090
YAML

client jordan frontend role=frontend
client jordan batch    role=batch

$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -f /course6/6/policy.yaml
REMOTE

waitdeploy jordan jordan-api || echo "  !! jordan-api did not become ready in time"
waitdeploy jordan frontend   || echo "  !! frontend did not become ready in time"
waitdeploy jordan batch      || echo "  !! batch did not become ready in time"

echo "READY q06 — jordan is wide open: both frontend and batch reach jordan-api on 8080 and 9090"
