#!/bin/bash
source "$(dirname "$0")/../common.sh"

ensure_helm_repo
nsdelete ruby
mkcourse /course4/8
$SSH_CP "rm -rf /course4/8/*"

echo "READY q08 — /course4/8 is empty, Namespace ruby does not exist"
