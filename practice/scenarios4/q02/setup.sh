#!/bin/bash
source "$(dirname "$0")/../common.sh"

ensure_helm_repo
nsdelete beryl
mkcourse /course4/2
$SSH_CP "rm -f /course4/2/*"

echo "READY q02 — Namespace beryl does not exist; repo hk-charts is added"
