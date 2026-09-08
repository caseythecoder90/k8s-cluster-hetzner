#!/bin/bash
# Remove everything Exam Set 5 created, and nothing else: its Namespaces
# (metals) and /course5 on the control plane. Sets 1-4 and 6 are untouched.
source "$(dirname "$0")/common.sh"

NS="copper silver cobalt nickel zinc tin iron chrome bronze pewter brass gallium indium osmium cadmium mercury"
echo "Deleting Namespaces: $NS"
kubectl delete namespace $NS --ignore-not-found --wait=false >/dev/null 2>&1 || true

echo "Removing /course5 on the control plane"
$SSH_CP "sudo rm -rf /course5" || true

echo "Done. Namespaces finish terminating in the background."
