#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe bronze
mkcourse $COURSE/9
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/9/base /course5/9/overlays
mkdir -p /course5/9/base /course5/9/overlays/prod
cat > /course5/9/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smelter
  labels:
    app: smelter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: smelter
  template:
    metadata:
      labels:
        app: smelter
    spec:
      containers:
        - name: app
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course5/9/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF
cat > /course5/9/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: bronze
resources:
  - ../../base
EOF
REMOTE
fingerprint q09-base "$COURSE/9/base/*.yaml"

echo "READY q09 — smelter base (no minReadySeconds, default grace period, one label) + overlay at /course5/9/overlays/prod"
