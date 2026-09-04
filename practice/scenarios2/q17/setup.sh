#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace helios --dry-run=client -o yaml | kubectl apply -f -
kubectl -n helios delete deployment helios-batch --ignore-not-found

# Idempotent: remove any prior instance of this exact taint before adding it,
# so re-running setup-all.sh doesn't error on "already has taint".
kubectl taint nodes lab-worker-1 dedicated=helios:NoSchedule- >/dev/null 2>&1 || true
kubectl taint nodes lab-worker-1 dedicated=helios:NoSchedule

echo "READY q17 — lab-worker-1 is now tainted (dedicated=helios:NoSchedule); see ../README.md"
