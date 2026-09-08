#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe iron
mkcourse $COURSE/7
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/7/base /course5/7/overlays
mkdir -p /course5/7/base /course5/7/overlays/prod
cat > /course5/7/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: refinery
spec:
  replicas: 1
  selector:
    matchLabels:
      app: refinery
  template:
    metadata:
      labels:
        app: refinery
    spec:
      containers:
        - name: app
          image: busybox:1
          command:
            - "sh"
            - "-c"
            - 'while true; do echo "flags: $@"; sleep 30; done'
            - "--"
          args:
            - "--mode=batch"
            - "--level=info"
            - "--retries=3"
          resources:
            requests: {cpu: 5m, memory: 8Mi}
EOF
cat > /course5/7/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF
cat > /course5/7/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: iron
resources:
  - ../../base
EOF
REMOTE
fingerprint q07-base "$COURSE/7/base/*.yaml"

echo "READY q07 — refinery's container takes a 3-element args list; overlay started at /course5/7/overlays/prod"
