#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe mekong nile
mkcourse $COURSE/7

webserver mekong mekong-db 1 mekong-db

# Identically labelled clients on both sides of the Namespace boundary — that
# is the whole point of the question.
client mekong mekong-client role=client
client nile   nile-client   role=client
client nile   nile-batch    role=batch

$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -f /course6/7/policy.yaml
REMOTE

waitdeploy mekong mekong-db     || echo "  !! mekong-db did not become ready in time"
waitdeploy mekong mekong-client || echo "  !! mekong-client did not become ready in time"
waitdeploy nile   nile-client   || echo "  !! nile-client did not become ready in time"
waitdeploy nile   nile-batch    || echo "  !! nile-batch did not become ready in time"

echo "READY q07 — mekong-db is open to all three clients; nile-client and mekong-client carry identical labels"
