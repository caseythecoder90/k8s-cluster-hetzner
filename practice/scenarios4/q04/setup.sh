#!/bin/bash
source "$(dirname "$0")/../common.sh"

ensure_helm_repo
nswipe garnet
mkcourse /course4/4
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -f /course4/4/revision /course4/4/chart-version
helm -n garnet install garnet-api hk-charts/api --version 1.0.0 --set replicaCount=2 >/dev/null
kubectl -n garnet rollout status deploy garnet-api --timeout=120s >/dev/null
# rev 2: a good upgrade
helm -n garnet upgrade garnet-api hk-charts/api --version 2.0.0 --reuse-values >/dev/null
kubectl -n garnet rollout status deploy garnet-api --timeout=120s >/dev/null
# rev 3: the bad one — a tag that doesn't exist, so the new Pods sit in ImagePullBackOff
helm -n garnet upgrade garnet-api hk-charts/api --version 2.2.0 --reuse-values --set image.tag=1.99-alpine >/dev/null
REMOTE

echo "READY q04 — garnet-api at revision 3 (broken), revision 2 was the last good one"
