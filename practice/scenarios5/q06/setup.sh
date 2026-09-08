#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe tin
mkcourse $COURSE/6
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/6/base /course5/6/overlays
mkdir -p /course5/6/base /course5/6/overlays/prod
cat > /course5/6/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: solder
spec:
  replicas: 1
  selector:
    matchLabels:
      app: solder
  template:
    metadata:
      labels:
        app: solder
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
        - name: cache
          image: redis:7-alpine
          resources:
            requests: {cpu: 5m, memory: 12Mi}
        - name: legacy
          image: busybox:1
          command: ["sh", "-c", "sleep 86400"]
          resources:
            requests: {cpu: 5m, memory: 8Mi}
EOF
cat > /course5/6/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF
cat > /course5/6/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: tin
resources:
  - ../../base
EOF
REMOTE
fingerprint q06-base "$COURSE/6/base/*.yaml"

echo "READY q06 — base with three containers (web, cache, legacy) + started overlay at /course5/6/overlays/prod"
