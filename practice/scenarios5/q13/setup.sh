#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe indium
mkcourse $COURSE/13
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course5/13/base /course5/13/overlays /course5/13/audit.yaml
mkdir -p /course5/13/base /course5/13/overlays/prod
cat > /course5/13/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: broker
  template:
    metadata:
      labels:
        app: broker
    spec:
      containers:
        - name: broker
          image: redis:7-alpine
          env:
            - name: BROKER_USER
              valueFrom:
                secretKeyRef:
                  name: broker-auth
                  key: username
            - name: BROKER_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: broker-auth
                  key: password
          resources:
            requests: {cpu: 5m, memory: 16Mi}
EOF
cat > /course5/13/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
EOF
cat > /course5/13/overlays/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: indium
resources:
  - ../../base
EOF
cat > /course5/13/overlays/prod/rules.conf <<'EOF'
max_message_bytes=65536
retention_hours=48
EOF
# The auditor is NOT part of the Kustomize build. It is applied straight to the
# cluster and mounts the ConfigMap by a fixed name.
cat > /course5/13/audit.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: audit
  namespace: indium
spec:
  replicas: 1
  selector:
    matchLabels:
      app: audit
  template:
    metadata:
      labels:
        app: audit
    spec:
      containers:
        - name: audit
          image: busybox:1
          command: ["sh", "-c", "sleep 86400"]
          volumeMounts:
            - name: rules
              mountPath: /etc/rules
          resources:
            requests: {cpu: 5m, memory: 8Mi}
      volumes:
        - name: rules
          configMap:
            name: broker-rules
EOF
kubectl apply -f /course5/13/audit.yaml >/dev/null
kubectl apply -k /course5/13/overlays/prod >/dev/null
REMOTE
fingerprint q13-base "$COURSE/13/base/*.yaml"

echo "READY q13 — broker and audit both applied into indium, both stuck on missing config"
