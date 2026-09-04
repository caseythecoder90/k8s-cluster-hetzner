#!/bin/bash
source "$(dirname "$0")/../common.sh"

mkcourse /course4/1
ensure_helm_repo
$SSH_CP "rm -f /course4/1/charts /course4/1/api-versions"

echo "READY q01 — repo served on the control plane at http://localhost:6100"
