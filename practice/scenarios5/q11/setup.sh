#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe brass
mkcourse $COURSE/11
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/11/base /course5/11/overlays
mkdir -p /course5/11/base /course5/11/overlays/prod
cat > /course5/11/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bell
  labels:
    app: bell
    app.kubernetes.io/managed-by: helm
  annotations:
    brass.io/team: brass
    nginx.ingress.kubernetes.io/rewrite-target: /
    brass.io/cost~center: "smelting-eu"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bell
  template:
    metadata:
      labels:
        app: bell
    spec:
      containers:
        - name: app
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course5/11/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF
cat > /course5/11/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: brass
resources:
  - ../../base
EOF
REMOTE
fingerprint q11-base "$COURSE/11/base/*.yaml"

echo "READY q11 — bell base with slash-and-tilde metadata keys + overlay at /course5/11/overlays/prod"
