#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe congo
mkcourse $COURSE/15

# Steady state of a canary that has been baking: 3 primary + 1 canary, both
# behind Service feed via the shared label tier=feed.
webserver congo feed-primary 3 feed-v1 tier=feed version=v1
client congo probe

CANARY_YAML='apiVersion: apps/v1
kind: Deployment
metadata:
  name: feed-canary
  namespace: congo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: feed-canary
  template:
    metadata:
      labels:
        app: feed-canary
        tier: feed
        version: v2
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          command: ["/bin/sh","-c","echo feed-v2 > /usr/share/nginx/html/index.html && exec nginx -g '"'"'daemon off;'"'"'"]
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}'

echo "$CANARY_YAML" | kubectl apply -f - >/dev/null

kubectl apply -f - >/dev/null <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: feed
  namespace: congo
spec:
  type: ClusterIP
  selector:
    tier: feed
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
EOF

$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course6/15
mkdir -p /course6/15
REMOTE
$SSH_CP "cat > /course6/15/feed-canary.yaml" <<EOF
# A copy of the live canary Deployment, for reference.
$CANARY_YAML
EOF

waitdeploy congo feed-primary
waitdeploy congo feed-canary
waitdeploy congo probe

echo "READY q15 — congo: feed-primary (3, feed-v1) + feed-canary (1, feed-v2) both behind Service feed, ~25% on the canary"
