#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe yangtze
mkcourse $COURSE/13
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course6/13
mkdir -p /course6/13
REMOTE

webserver yangtze orders-blue  2 orders-v1 track=blue
webserver yangtze orders-green 2 orders-v2 track=green
client yangtze probe

kubectl apply -f - >/dev/null <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: orders
  namespace: yangtze
spec:
  type: ClusterIP
  selector:
    track: blue
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
EOF

waitdeploy yangtze orders-blue
waitdeploy yangtze orders-green
waitdeploy yangtze probe

echo "READY q13 — yangtze: orders-blue (2, live via Service orders) and orders-green (2, dark), no test Service yet"
