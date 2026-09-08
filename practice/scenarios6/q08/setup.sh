#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe oder rhine
mkcourse $COURSE/8

webserver oder oder-api 1 oder-api

# Three clients, arranged so that each wrong spelling of the from: block lets
# in a Pod that must be blocked:
#   rhine-web    right label, right Namespace  -> allowed
#   rhine-batch  wrong label, right Namespace  -> blocked (OR would let it in)
#   oder-web     right label, wrong Namespace  -> blocked (OR would let it in)
client rhine rhine-web   role=web
client rhine rhine-batch role=batch
client oder  oder-web    role=web

$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -f /course6/8/policy.yaml
REMOTE

waitdeploy oder  oder-api    || echo "  !! oder-api did not become ready in time"
waitdeploy rhine rhine-web   || echo "  !! rhine-web did not become ready in time"
waitdeploy rhine rhine-batch || echo "  !! rhine-batch did not become ready in time"
waitdeploy oder  oder-web    || echo "  !! oder-web did not become ready in time"

echo "READY q08 — oder-api is open to all three clients (rhine-web, rhine-batch, oder-web)"
