#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q09:"

exists ckad-old  && fail "container ckad-old still exists — it is the one holding port 18081" || pass "ckad-old removed"
exists ckad-dead && fail "container ckad-dead still exists (docker ps -a to see exited containers)" || pass "ckad-dead removed"

imgexists ckad-junk:v1 && fail "image ckad-junk:v1 still present" || pass "image ckad-junk:v1 removed"

if imgexists ckad-junk:v1; then :; else
  dang=$(docker images -f dangling=true -q | wc -l | tr -d ' ')
  [[ "$dang" -eq 0 ]] && pass "no dangling images left behind" \
    || echo "  · note: $dang dangling image(s) on this machine (rmi -f on a referenced image leaves these)"
fi

running ckad-new && pass "container ckad-new is running" || { fail "no running container named ckad-new"; exit 1; }
img=$(ins ckad-new '{{.Config.Image}}')
[[ "$img" == nginx:1-alpine ]] && pass "ckad-new runs nginx:1-alpine" || fail "ckad-new runs '$img'"
hp=$(hostport ckad-new 80)
[[ "$hp" == "18081" ]] && pass "ckad-new published on host port 18081" || fail "ckad-new is on host port '$hp' (expected 18081)"

exit ${FAILED}
