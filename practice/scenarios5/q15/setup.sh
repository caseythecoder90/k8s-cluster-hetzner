#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe cadmium
mkcourse $COURSE/15
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/15/base /course5/15/overlays
mkdir -p /course5/15/base /course5/15/overlays/staging
cat > /course5/15/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pigment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pigment
  template:
    metadata:
      labels:
        app: pigment
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: config
              mountPath: /etc/pigment
          resources:
            requests: {cpu: 5m, memory: 12Mi}
      volumes:
        - name: config
          configMap:
            name: pigment-config
EOF
cat > /course5/15/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: pigment
spec:
  selector:
    app: pigment
  ports:
    - port: 80
      targetPort: 80
EOF
cat > /course5/15/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF
# The data file is correct and correctly named. The kustomization is not.
cat > /course5/15/overlays/staging/app.conf <<'EOF'
palette=cadmium
dither=off
EOF
# fault 1: configmapGenerator  (the field is configMapGenerator)
# fault 2: ../base             (the base is two levels up from overlays/staging)
# fault 3: app.config          (the file on disk is app.conf)
cat > /course5/15/overlays/staging/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: cadmium
namePrefix: stg-

resources:
  - ../base

replicas:
  - name: pigment
    count: 2

configmapGenerator:
  - name: pigment-config
    files:
      - app.config
EOF
REMOTE
fingerprint q15-base "$COURSE/15/base/*.yaml"

echo "READY q15 — /course5/15/overlays/staging does not render (three faults, nothing deployed)"
