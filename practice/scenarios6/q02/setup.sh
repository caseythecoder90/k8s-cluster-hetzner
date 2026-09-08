#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe danube
mkcourse $COURSE/2

webserver danube danube-web 2 danube-web
client   danube probe

$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -f /course6/2/service.yaml
REMOTE

waitdeploy danube danube-web || echo "  !! danube-web did not become ready in time"
waitdeploy danube probe      || echo "  !! probe did not become ready in time"

echo "READY q02 — Deployment danube-web (2 Pods, nginx on container port 80) and no Service yet"
