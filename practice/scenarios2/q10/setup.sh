#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace hera --dry-run=client -o yaml | kubectl apply -f -
kubectl -n hera delete deployment hera-worker --ignore-not-found

kubectl -n hera apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hera-worker
spec:
  replicas: 1
  selector:
    matchLabels: {app: hera-worker}
  template:
    metadata:
      labels: {app: hera-worker}
    spec:
      containers:
        - name: worker
          image: busybox:1
          # BUG: this binary doesn't exist in busybox -> CrashLoopBackOff
          command: ["/usr/bin/definitely-not-a-real-binary"]
          resources: {requests: {cpu: 10m, memory: 16Mi}}
EOF

$SSH_CP "sudo mkdir -p /course2/10 && sudo chown deploy:deploy /course2/10 && rm -f /course2/10/root-cause.txt"
echo "READY q10 — give it ~20s to start crash-looping, then solve on: $SSH_CP"
