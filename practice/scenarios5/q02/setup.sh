#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe silver
mkcourse $COURSE/2
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/2/base /course5/2/overlays
mkdir -p /course5/2/base /course5/2/overlays/prod
cat > /course5/2/base/api.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: main
          image: nginx:1-alpine
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course5/2/base/cache.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      containers:
        - name: store
          image: redis-oss:7-alpine
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course5/2/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - api.yaml
  - cache.yaml
EOF
cat > /course5/2/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: silver
namePrefix: sv-
resources:
  - ../../base
EOF
REMOTE
fingerprint q02-base "$COURSE/2/base/*.yaml"

echo "READY q02 — base + a started overlay at /course5/2/overlays/prod"
