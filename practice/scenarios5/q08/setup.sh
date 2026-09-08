#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe chrome
mkcourse $COURSE/8
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/8/base /course5/8/overlays
mkdir -p /course5/8/base /course5/8/overlays/prod
cat > /course5/8/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: plating
  labels:
    app: plating
    retired: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: plating
  template:
    metadata:
      labels:
        app: plating
    spec:
      containers:
        - name: app
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          env:
            - name: LOG_LEVEL
              value: info
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course5/8/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF
cat > /course5/8/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: chrome
resources:
  - ../../base
EOF
REMOTE
fingerprint q08-base "$COURSE/8/base/*.yaml"

echo "READY q08 — plating base (LOG_LEVEL=info, no imagePullPolicy, label retired=true) + overlay at /course5/8/overlays/prod"
