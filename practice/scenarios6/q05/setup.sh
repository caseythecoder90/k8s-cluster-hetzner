#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe indus
mkcourse $COURSE/5

webserver indus indus-web 1 indus-web
client   indus indus-client

$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -f /course6/5/policy.yaml
REMOTE

waitdeploy indus indus-web    || echo "  !! indus-web did not become ready in time"
waitdeploy indus indus-client || echo "  !! indus-client did not become ready in time"

echo "READY q05 — indus is wide open: indus-client can reach indus-web and no NetworkPolicy exists"
