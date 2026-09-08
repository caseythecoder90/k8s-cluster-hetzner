#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe elbe
mkcourse $COURSE/16
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course6/16
mkdir -p /course6/16
REMOTE

webserver elbe site 1 site-home
webserver elbe api  1 api-payload

# The api Service deliberately publishes 8080 in front of the container's 80,
# so the Ingress backend port has to be the SERVICE port, not the pod's.
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: site
  namespace: elbe
spec:
  type: ClusterIP
  selector:
    app: site
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: elbe
spec:
  type: ClusterIP
  selector:
    app: api
  ports:
    - name: http
      protocol: TCP
      port: 8080
      targetPort: 80
EOF

waitdeploy elbe site
waitdeploy elbe api

echo "READY q16 — elbe: Services site (:80) and api (:8080 -> 80), no Ingress yet (and no ingress controller in this lab)"
