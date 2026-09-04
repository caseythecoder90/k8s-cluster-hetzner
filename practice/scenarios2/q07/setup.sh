#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace poseidon --dry-run=client -o yaml | kubectl apply -f -
kubectl -n poseidon delete pod poseidon-web --ignore-not-found --force --grace-period=0 2>/dev/null || true

kubectl -n poseidon apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: poseidon-web
spec:
  containers:
    - name: web
      image: busybox:1
      command: ["/bin/sh", "-c"]
      args:
        - 'i=0; while true; do i=$((i+1)); echo "request $i ok" >> /var/log/app/access.log; sleep 3; done'
      volumeMounts:
        - name: logs
          mountPath: /var/log/app
      resources: {requests: {cpu: 10m, memory: 16Mi}}
  volumes:
    - name: logs
      emptyDir: {}
EOF

echo "READY q07 — give it ~10s to write some log lines first"
