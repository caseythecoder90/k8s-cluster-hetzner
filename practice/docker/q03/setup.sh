#!/bin/bash
source "$(dirname "$0")/../common.sh"
d="$WORK/q03"; rm -rf "$d"; mkdir -p "$d"
crm ckad-web
pullbase nginx:1-alpine
echo "  q03 ready: $d (host port 18080 is free for you)"
