#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe pewter
mkcourse $COURSE/10
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/10/base /course5/10/overlays
mkdir -p /course5/10/base /course5/10/overlays/prod
cat > /course5/10/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: foundry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: foundry
  template:
    metadata:
      labels:
        app: foundry
    spec:
      containers:
        - name: app
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
        - name: log
          image: busybox:1
          command: ["sh", "-c", "while true; do echo log; sleep 30; done"]
          resources:
            requests: {cpu: 5m, memory: 8Mi}
EOF
cat > /course5/10/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF
cat > /course5/10/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: pewter
resources:
  - ../../base
EOF
REMOTE
fingerprint q10-base "$COURSE/10/base/*.yaml"

echo "READY q10 — foundry base with containers [app, log] + overlay at /course5/10/overlays/prod"
