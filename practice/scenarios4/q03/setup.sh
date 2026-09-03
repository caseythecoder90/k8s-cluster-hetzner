#!/bin/bash
source "$(dirname "$0")/../common.sh"

ensure_helm_repo
nswipe coral
mkcourse /course4/3
$SSH_CP "rm -f /course4/3/revision && helm -n coral install coral-web hk-charts/nginx --version 1.0.0 \
  --set replicaCount=4 --set service.type=NodePort --set service.nodePort=30403 >/dev/null"
kubectl -n coral rollout status deploy coral-web --timeout=120s >/dev/null

echo "READY q03 — coral-web at nginx-1.0.0, 4 replicas, NodePort 30403"
