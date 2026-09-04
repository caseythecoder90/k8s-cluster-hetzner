#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe topaz
mkcourse /course4/9
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course4/9/app /course4/9/rendered.yaml /course4/9/count
mkdir -p /course4/9/app
cat > /course4/9/app/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: topaz-web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: topaz-web
  template:
    metadata:
      labels:
        app: topaz-web
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course4/9/app/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: topaz-web
spec:
  selector:
    app: topaz-web
  ports:
    - port: 80
      targetPort: 80
EOF
cat > /course4/9/app/configmap.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: topaz-config
data:
  MOTD: "hello from topaz"
EOF
cat > /course4/9/app/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
EOF
REMOTE

echo "READY q09 — Kustomization at /course4/9/app, Namespace topaz empty"
