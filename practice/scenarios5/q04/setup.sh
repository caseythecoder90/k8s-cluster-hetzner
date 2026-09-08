#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe nickel
mkcourse $COURSE/4
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/4/base /course5/4/overlays
mkdir -p /course5/4/base /course5/4/overlays/dev
cat > /course5/4/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: worker
  template:
    metadata:
      labels:
        app: worker
    spec:
      containers:
        - name: app
          image: busybox:1
          command: ["sh", "-c", "sleep 86400"]
          resources:
            requests: {cpu: 5m, memory: 8Mi}
EOF
cat > /course5/4/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF
cat > /course5/4/overlays/dev/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: nickel
resources:
  - ../../base
EOF
REMOTE
fingerprint q04-base "$COURSE/4/base/*.yaml"

echo "READY q04 — base + started overlay at /course5/4/overlays/dev"
