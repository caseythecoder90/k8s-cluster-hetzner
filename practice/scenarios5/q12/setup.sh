#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe gallium
mkcourse $COURSE/12
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/12/base /course5/12/overlays
mkdir -p /course5/12/base /course5/12/overlays/prod/content
cat > /course5/12/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: renderer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: renderer
  template:
    metadata:
      labels:
        app: renderer
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          env:
            - name: MAX_CONNECTIONS
              valueFrom:
                configMapKeyRef:
                  name: gallium-config
                  key: MAX_CONNECTIONS
          volumeMounts:
            - name: config
              mountPath: /etc/gallium
          resources:
            requests: {cpu: 5m, memory: 12Mi}
      volumes:
        - name: config
          configMap:
            name: gallium-config
EOF
cat > /course5/12/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF
cat > /course5/12/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: gallium
resources:
  - ../../base
EOF
cat > /course5/12/overlays/prod/app.properties <<'EOF'
color=teal
mode=prod
EOF
cat > /course5/12/overlays/prod/content/landing.html <<'EOF'
<h1>Gallium</h1>
EOF
cat > /course5/12/overlays/prod/runtime.env <<'EOF'
MAX_CONNECTIONS=64
CACHE_TTL=300
EOF
kubectl apply -k /course5/12/overlays/prod >/dev/null
REMOTE
fingerprint q12-base "$COURSE/12/base/*.yaml"

echo "READY q12 — renderer applied into gallium, Pod stuck on the missing ConfigMap"
