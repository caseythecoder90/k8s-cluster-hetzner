#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe mercury
mkcourse $COURSE/16
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/16/base /course5/16/overlays
mkdir -p /course5/16/base /course5/16/overlays/prod
cat > /course5/16/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gauge
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gauge
  template:
    metadata:
      labels:
        app: gauge
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          env:
            - name: MODE
              value: "gauge"
          ports:
            - containerPort: 80
          volumeMounts:
            - name: config
              mountPath: /etc/gauge
          resources:
            requests: {cpu: 5m, memory: 12Mi}
      volumes:
        - name: config
          configMap:
            name: gauge-config
EOF
cat > /course5/16/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: gauge
spec:
  selector:
    app: gauge
  ports:
    - port: 80
      targetPort: 80
EOF
cat > /course5/16/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF
REMOTE
fingerprint q16-base "$COURSE/16/base/*.yaml"

echo "READY q16 — base at /course5/16/base, /course5/16/overlays/prod is empty"
