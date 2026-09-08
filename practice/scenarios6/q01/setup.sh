#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe amazon
mkcourse $COURSE/1

webserver amazon amazon-web 2 amazon-web
client   amazon probe

$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -f /course6/1/service.yaml
cat > /course6/1/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: amazon-web
  namespace: amazon
spec:
  type: ClusterIP
  selector:
    app: amazon-api
  ports:
    - port: 80
      targetPort: 80
EOF
kubectl apply -f /course6/1/service.yaml >/dev/null
REMOTE

waitdeploy amazon amazon-web || echo "  !! amazon-web did not become ready in time"
waitdeploy amazon probe      || echo "  !! probe did not become ready in time"

echo "READY q01 — Service amazon-web exists, 2 Pods are Ready, and nothing can reach the Service"
