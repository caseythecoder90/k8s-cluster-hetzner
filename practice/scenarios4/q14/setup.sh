#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe slate
mkcourse /course4/14
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course4/14/base /course4/14/overlays
mkdir -p /course4/14/base /course4/14/overlays/prod
cat > /course4/14/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slate-web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: slate-web
  template:
    metadata:
      labels:
        app: slate-web
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course4/14/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: slate-web
spec:
  selector:
    app: slate-web
  ports:
    - port: 80
      targetPort: 80
EOF
# bug 1: the file is deployment.yaml
cat > /course4/14/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yml
  - service.yaml
EOF
# bug 2: wrong relative path to the base;  bug 3: the field is commonLabels (plural)
cat > /course4/14/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: slate
resources:
  - ../base
commonLabel:
  team: slate
replicas:
  - name: slate-web
    count: 2
EOF
REMOTE
fingerprint q14-manifests /course4/14/base/deployment.yaml /course4/14/base/service.yaml

echo "READY q14 — /course4/14/overlays/prod does not render"
