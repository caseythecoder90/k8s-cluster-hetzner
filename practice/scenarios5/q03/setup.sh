#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe cobalt
mkcourse $COURSE/3
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/3/base /course5/3/overlays
mkdir -p /course5/3/base
cat > /course5/3/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portal
spec:
  replicas: 2
  selector:
    matchLabels:
      app: portal
  template:
    metadata:
      labels:
        app: portal
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course5/3/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: portal
spec:
  selector:
    app: portal
  ports:
    - port: 80
      targetPort: 80
EOF
cat > /course5/3/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: cobalt
resources:
  - deployment.yaml
  - service.yaml
EOF
REMOTE
# The Deployment is already LIVE — that is what makes the wrong answer fail.
$SSH_CP "kubectl apply -k /course5/3/base >/dev/null"
kubectl -n cobalt rollout status deploy portal --timeout=120s >/dev/null
fingerprint q03-base "$COURSE/3/base/*.yaml"

echo "READY q03 — portal is already running in cobalt from /course5/3/base"
