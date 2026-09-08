#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe tiber
mkcourse $COURSE/11
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course6/11
mkdir -p /course6/11
REMOTE

# api is the workload the policy attaches to. It is an nginx pod, so it both
# serves (for the ingress checks) and can run wget (for the egress checks).
webserver tiber api     1 api-v1
webserver tiber logs    1 logs-v1
webserver tiber billing 1 billing-v1

client tiber frontend
client tiber scanner

kubectl apply -f - >/dev/null <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: tiber
spec:
  selector:
    app: api
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: logs
  namespace: tiber
spec:
  selector:
    app: logs
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: billing
  namespace: tiber
spec:
  selector:
    app: billing
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
EOF

waitdeploy tiber api
waitdeploy tiber logs
waitdeploy tiber billing
waitdeploy tiber frontend
waitdeploy tiber scanner

echo "READY q11 — tiber: api + logs + billing Services, frontend + scanner clients, no NetworkPolicy yet (everything reaches everything)"
