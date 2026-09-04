#!/bin/bash
# Remove everything Exam Set 4 created, and nothing else: its Namespaces
# (gemstones), /course4 on the control plane, the chart server on :6100 and
# the hk-charts repo entry. Sets 1-3 on the same cluster are untouched.
source "$(dirname "$0")/common.sh"

NS="beryl coral garnet jade onyx opal pearl quartz ruby topaz zircon agate jasper lapis slate amethyst amethyst-dev obsidian obsidian-dev"
echo "Deleting Namespaces: $NS"
kubectl delete namespace $NS --ignore-not-found --wait=false >/dev/null 2>&1 || true

echo "Removing /course4, the chart server and the repo entry on the control plane"
$SSH_CP "pkill -f 'http.server 6100' >/dev/null 2>&1; helm repo remove hk-charts >/dev/null 2>&1; sudo rm -rf /course4" || true

echo "Done. Namespaces finish terminating in the background."
