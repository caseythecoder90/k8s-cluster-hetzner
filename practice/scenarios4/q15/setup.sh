#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe amethyst-dev amethyst
mkcourse /course4/15
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course4/15/base /course4/15/overlays
mkdir -p /course4/15/base /course4/15/overlays/dev /course4/15/overlays/prod
mkdeploy() { # mkdeploy <name> <image> <port>
  cat > "/course4/15/base/$1.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $1
  template:
    metadata:
      labels:
        app: $1
    spec:
      containers:
        - name: $1
          image: $2
          ports:
            - containerPort: $3
          resources:
            requests: {cpu: 5m, memory: 12Mi}
---
apiVersion: v1
kind: Service
metadata:
  name: $1
spec:
  selector:
    app: $1
  ports:
    - port: $3
      targetPort: $3
EOF
}
mkdeploy web   nginx:1-alpine 80
mkdeploy cache redis:7-alpine 6379
cat > /course4/15/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - web.yaml
  - cache.yaml
EOF
cat > /course4/15/overlays/dev/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: amethyst-dev
resources:
  - ../../base
EOF
cat > /course4/15/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: amethyst
resources:
  - ../../base
EOF
kubectl apply -k /course4/15/overlays/dev >/dev/null
REMOTE
fingerprint q15-base "/course4/15/base/*.yaml"
kubectl -n amethyst-dev rollout status deploy web --timeout=120s >/dev/null

echo "READY q15 — dev deployed in amethyst-dev, prod not deployed yet"
