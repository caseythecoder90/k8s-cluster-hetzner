#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe jasper
mkcourse /course4/12
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course4/12/base /course4/12/overlays
mkdir -p /course4/12/base /course4/12/overlays/dev
cat > /course4/12/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jasper-worker
  annotations:
    jasper.io/team: jasper
    jasper.io/legacy-owner: someone-who-left@example.com
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jasper-worker
  template:
    metadata:
      labels:
        app: jasper-worker
    spec:
      containers:
        - name: worker
          image: busybox:1
          command: ["sh", "-c", "while true; do echo \"mode=$MODE debug=$DEBUG\"; sleep 30; done"]
          env:
            - name: MODE
              value: batch
          resources:
            requests: {cpu: 5m, memory: 8Mi}
EOF
cat > /course4/12/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF
cat > /course4/12/overlays/dev/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: jasper
resources:
  - ../../base
EOF
kubectl apply -k /course4/12/overlays/dev >/dev/null
REMOTE
fingerprint q12-base "/course4/12/base/*.yaml"
kubectl -n jasper rollout status deploy jasper-worker --timeout=120s >/dev/null

echo "READY q12 — jasper-worker deployed from the dev overlay (MODE=batch, two annotations)"
