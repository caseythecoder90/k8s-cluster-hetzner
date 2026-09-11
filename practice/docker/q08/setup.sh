#!/bin/bash
source "$(dirname "$0")/../common.sh"
d="$WORK/q08"; rm -rf "$d"; mkdir -p "$d"
pullbase nginx:1-alpine
echo "  q08 ready: $d"
