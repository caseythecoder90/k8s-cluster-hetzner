#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace athena --dry-run=client -o yaml | kubectl apply -f -
kubectl -n athena delete deployment athena-web --ignore-not-found

kubectl -n athena apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: athena-config
data:
  APP_MODE: production
  LOG_LEVEL: info
EOF

echo "READY q02"
