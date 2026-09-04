#!/bin/bash
source "$(dirname "$0")/../common.sh"

ensure_helm_repo
nswipe quartz
mkcourse /course4/7
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
cat > /course4/7/values.yaml <<'EOF'
# quartz-api — production values
replicaCount: 2

image:
  repository: nginx
  tag: 1.27-alpin

service:
  type: NodePort
  nodePort: 30407

resources:
  requests:
    cpu: 10m
    memory: 16Mi
EOF
helm -n quartz install quartz-api hk-charts/api --version 2.2.0 -f /course4/7/values.yaml >/dev/null
REMOTE

echo "READY q07 — quartz-api installed, Pods in ImagePullBackOff"
