#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe copper
mkcourse $COURSE/1
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/1/base /course5/1/overlays /course5/1/rendered.yaml
mkdir -p /course5/1/base
cat > /course5/1/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course5/1/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
EOF
cat > /course5/1/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF
REMOTE
fingerprint q01-base "$COURSE/1/base/*.yaml"

echo "READY q01 — base at /course5/1/base, no overlay yet"
