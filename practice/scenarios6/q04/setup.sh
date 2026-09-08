#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe hudson
mkcourse $COURSE/4

webserver hudson hudson-web 2 hudson-web
client   hudson probe

$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -f /course6/4/service.yaml
cat > /course6/4/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: hudson-web
  namespace: hudson
spec:
  type: ClusterIP
  selector:
    app: hudson-web
  ports:
    - port: 80
      targetPort: 8080
EOF
kubectl apply -f /course6/4/service.yaml >/dev/null
REMOTE

waitdeploy hudson hudson-web || echo "  !! hudson-web did not become ready in time"
waitdeploy hudson probe      || echo "  !! probe did not become ready in time"

echo "READY q04 — Service hudson-web HAS Endpoints and still refuses every connection"
