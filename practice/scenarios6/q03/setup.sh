#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe ganges
mkcourse $COURSE/3

# Not the webserver helper: this question needs a container with two NAMED
# ports, so nginx is given two server blocks serving two different pages.
kubectl apply -f - >/dev/null <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ganges-web
  namespace: ganges
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ganges-web
  template:
    metadata:
      labels:
        app: ganges-web
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          command:
            - /bin/sh
            - -c
            - |
              mkdir -p /usr/share/nginx/html /usr/share/nginx/metrics
              echo ganges-web > /usr/share/nginx/html/index.html
              echo ganges-metrics > /usr/share/nginx/metrics/index.html
              printf 'server { listen 80; root /usr/share/nginx/html; }\nserver { listen 9113; root /usr/share/nginx/metrics; }\n' > /etc/nginx/conf.d/default.conf
              exec nginx -g 'daemon off;'
          ports:
            - name: http
              containerPort: 80
            - name: metrics
              containerPort: 9113
          resources:
            requests: {cpu: 5m, memory: 12Mi}
YAML

client ganges probe

$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -f /course6/3/service.yaml
REMOTE

waitdeploy ganges ganges-web || echo "  !! ganges-web did not become ready in time"
waitdeploy ganges probe      || echo "  !! probe did not become ready in time"

echo "READY q03 — ganges-web listens on named ports http/80 and metrics/9113, no Service yet"
