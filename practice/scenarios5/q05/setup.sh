#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe zinc
mkcourse $COURSE/5
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/5/base /course5/5/overlays
mkdir -p /course5/5/base /course5/5/overlays/dev
cat > /course5/5/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ledger
  annotations:
    zinc.io/team: zinc
    zinc.io/deprecated: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ledger
  template:
    metadata:
      labels:
        app: ledger
    spec:
      nodeSelector:
        disktype: ssd
      containers:
        - name: app
          image: busybox:1
          command: ["sh", "-c", "sleep 86400"]
          resources:
            requests: {cpu: 5m, memory: 8Mi}
EOF
cat > /course5/5/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF
cat > /course5/5/overlays/dev/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: zinc
resources:
  - ../../base
EOF
REMOTE
fingerprint q05-base "$COURSE/5/base/*.yaml"

echo "READY q05 — ledger's Pod will stay Pending until the overlay is right"
