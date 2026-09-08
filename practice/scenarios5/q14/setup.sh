#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe osmium
mkcourse $COURSE/14
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/14/base /course5/14/overlays
mkdir -p /course5/14/base /course5/14/overlays/prod
cat > /course5/14/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog
spec:
  replicas: 1
  selector:
    matchLabels:
      app: catalog
  template:
    metadata:
      labels:
        app: catalog
    spec:
      containers:
        - name: app
          image: nginx:1-alpine
          envFrom:
            - configMapRef:
                name: app-settings
            - configMapRef:
                name: feature-flags
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course5/14/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
configMapGenerator:
  - name: app-settings
    literals:
      - LOG_LEVEL=info
      - REGION=eu-west
      - TIMEOUT=30
  - name: feature-flags
    literals:
      - beta_ui=false
      - dark_mode=false
      - new_billing=false
EOF
cat > /course5/14/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: osmium
resources:
  - ../../base
EOF
kubectl apply -k /course5/14/overlays/prod >/dev/null
REMOTE
fingerprint q14-base "$COURSE/14/base/*.yaml"

echo "READY q14 — catalog running in osmium with the base's two generated ConfigMaps"
