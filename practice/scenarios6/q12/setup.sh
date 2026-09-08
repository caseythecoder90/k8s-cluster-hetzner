#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe volga
mkcourse $COURSE/12

# blue is live, green is deployed but dark. Pods carry a track label on top of
# the app label, and the Service selects the track — that is the whole trick.
webserver volga checkout-blue  3 blue-v1  track=blue
webserver volga checkout-green 3 green-v2 track=green
client volga probe

SVC_YAML='apiVersion: v1
kind: Service
metadata:
  name: checkout
  namespace: volga
spec:
  type: ClusterIP
  selector:
    track: blue
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80'

echo "$SVC_YAML" | kubectl apply -f - >/dev/null

$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course6/12
mkdir -p /course6/12
REMOTE
$SSH_CP "cat > /course6/12/checkout-svc.yaml" <<EOF
# A copy of the live Service, for reference. Edit-and-apply this or patch the
# Service in place — either is fine.
$SVC_YAML
EOF

waitdeploy volga checkout-blue
waitdeploy volga checkout-green
waitdeploy volga probe

echo "READY q12 — volga: checkout-blue (3, live) and checkout-green (3, dark), Service checkout selects track=blue"
