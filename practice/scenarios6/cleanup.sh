#!/bin/bash
# Remove everything Exam Set 6 created, and nothing else: its Namespaces
# (rivers) and /course6 on the control plane. Sets 1-5 are untouched.
source "$(dirname "$0")/common.sh"

NS="amazon danube ganges hudson indus jordan mekong nile oder rhine seine thames tiber volga yangtze zambezi congo elbe"
echo "Deleting Namespaces: $NS"
kubectl delete namespace $NS --ignore-not-found --wait=false >/dev/null 2>&1 || true

echo "Removing /course6 on the control plane"
$SSH_CP "sudo rm -rf /course6" || true

echo "Done. Namespaces finish terminating in the background."
