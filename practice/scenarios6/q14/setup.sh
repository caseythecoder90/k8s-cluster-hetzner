#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe zambezi
mkcourse $COURSE/14

# The primary already carries the shared label the Service selects on.
webserver zambezi shop-primary 4 shop-v1 tier=shop version=v1
client zambezi probe

kubectl apply -f - >/dev/null <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: shop
  namespace: zambezi
spec:
  type: ClusterIP
  selector:
    tier: shop
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
EOF

# The canary manifest is written but NOT applied — the student applies it.
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course6/14
mkdir -p /course6/14
cat > /course6/14/shop-canary.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-canary
  namespace: zambezi
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop-canary
  template:
    metadata:
      labels:
        app: shop-canary
        version: v2
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          command: ["/bin/sh","-c","echo shop-v2 > /usr/share/nginx/html/index.html && exec nginx -g 'daemon off;'"]
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
REMOTE

waitdeploy zambezi shop-primary
waitdeploy zambezi probe

echo "READY q14 — zambezi: shop-primary (4, serving 100% via Service shop), canary manifest at /course6/14/shop-canary.yaml, not applied"
