#!/bin/bash
source "$(dirname "$0")/../common.sh"

ensure_helm_repo
nswipe jade onyx opal
mkcourse /course4/5
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -f /course4/5/stuck /course4/5/count
helm -n jade install jade-api   hk-charts/api   --version 2.0.0 >/dev/null
helm -n jade install jade-cache hk-charts/redis --version 0.6.0 >/dev/null
helm -n onyx install onyx-web    hk-charts/nginx --version 1.0.0 --set replicaCount=2 >/dev/null
helm -n onyx install onyx-legacy hk-charts/nginx --version 1.0.0 >/dev/null
# The stuck one lives in a Namespace the task never mentions.
helm -n opal install report-generator hk-charts/api --version 2.0.0 >/dev/null
helm -n opal upgrade report-generator hk-charts/api --version 2.1.0 >/dev/null
REMOTE
# ...and its latest revision is frozen mid-upgrade, the way a killed helm process leaves it
force_release_status opal report-generator 2 pending-upgrade

echo "READY q05 — releases in jade (2), onyx (2) and one stuck somewhere"
