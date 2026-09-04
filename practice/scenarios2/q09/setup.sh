#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace ares --dry-run=client -o yaml | kubectl apply -f -
kubectl -n ares delete deployment ares-report --ignore-not-found
kubectl -n ares delete pod ares-report --ignore-not-found --force --grace-period=0 2>/dev/null || true

kubectl -n ares apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: ares-report-config
data:
  report.txt: |
    Q3 status: green
    Owner: Team Ares
EOF

$SSH_CP "sudo mkdir -p /course2/9 && sudo chown deploy:deploy /course2/9 && rm -f /course2/9/ares-report-deployment.yaml && cat > /course2/9/ares-report-pod.yaml <<'YAMLEOF'
apiVersion: v1
kind: Pod
metadata:
  name: ares-report
  namespace: ares
spec:
  containers:
  - name: report
    image: nginx:1-alpine
    resources:
      requests:
        cpu: 10m
        memory: 16Mi
YAMLEOF
kubectl --kubeconfig ~/.kube/config apply -f /course2/9/ares-report-pod.yaml"

echo "READY q09 — solve on: $SSH_CP"
