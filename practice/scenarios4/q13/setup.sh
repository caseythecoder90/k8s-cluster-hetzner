#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe lapis
mkcourse /course4/13
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course4/13/base /course4/13/overlays
mkdir -p /course4/13/base /course4/13/overlays/prod
cat > /course4/13/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lapis-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lapis-app
  template:
    metadata:
      labels:
        app: lapis-app
    spec:
      containers:
        - name: app
          image: nginx:1-alpine
          env:
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: db-creds
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-creds
                  key: password
          volumeMounts:
            - name: config
              mountPath: /etc/app-config
          resources:
            requests: {cpu: 5m, memory: 12Mi}
      volumes:
        - name: config
          configMap:
            name: app-config
EOF
cat > /course4/13/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF
cat > /course4/13/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: lapis
resources:
  - ../../base
EOF
cat > /course4/13/overlays/prod/app.properties <<'EOF'
color=blue
mode=prod
EOF
kubectl apply -k /course4/13/overlays/prod >/dev/null
REMOTE
fingerprint q13-base "/course4/13/base/*.yaml"

echo "READY q13 — lapis-app deployed, Pod stuck on the missing ConfigMap/Secret"
