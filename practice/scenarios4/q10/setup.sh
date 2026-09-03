#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe zircon
mkcourse /course4/10
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course4/10/base /course4/10/overlays
mkdir -p /course4/10/base
cat > /course4/10/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course4/10/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
EOF
cat > /course4/10/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF
REMOTE
fingerprint q10-base "/course4/10/base/*.yaml"

echo "READY q10 — base at /course4/10/base, no overlays yet"
