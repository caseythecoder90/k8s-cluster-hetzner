#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe agate
mkcourse /course4/11
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course4/11/base /course4/11/overlays
mkdir -p /course4/11/base /course4/11/overlays/prod
cat > /course4/11/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: agate-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: agate-api
  template:
    metadata:
      labels:
        app: agate-api
    spec:
      containers:
        - name: api
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course4/11/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: agate-api
spec:
  selector:
    app: agate-api
  ports:
    - port: 80
      targetPort: 80
EOF
cat > /course4/11/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF
cat > /course4/11/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: agate
resources:
  - ../../base
replicas:
  - name: agate-api
    count: 2
EOF
kubectl apply -k /course4/11/overlays/prod >/dev/null
REMOTE
fingerprint q11-base "/course4/11/base/*.yaml"
kubectl -n agate rollout status deploy agate-api --timeout=120s >/dev/null

echo "READY q11 — prod overlay deployed in agate (2 replicas, no probe, tiny requests)"
