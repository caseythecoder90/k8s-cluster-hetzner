#!/bin/bash
source "$(dirname "$0")/../common.sh"

ensure_helm_repo
nswipe pearl
mkcourse /course4/6
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course4/6/chart /course4/6/pearl-web.yaml /course4/6/prod-values.yaml
cp -r /course4/_repo/src/api /course4/6/chart
sed -i 's/^version: .*/version: 2.2.0/; s/^appVersion: .*/appVersion: "2.2"/' /course4/6/chart/Chart.yaml
cat > /course4/6/prod-values.yaml <<'EOF'
replicaCount: 2
image:
  tag: 1.27-alpine
service:
  type: NodePort
  nodePort: 30406
env:
  - name: LOG_LEVEL
    value: info
EOF
REMOTE

echo "READY q06 — chart at /course4/6/chart, values at /course4/6/prod-values.yaml"
