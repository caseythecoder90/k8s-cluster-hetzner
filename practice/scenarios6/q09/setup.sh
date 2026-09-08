#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe seine
mkcourse $COURSE/9
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course6/9
mkdir -p /course6/9
REMOTE

# payments  — the one backend checkout is allowed to talk to
# analytics — a second backend it must NOT be able to reach
webserver seine payments  1 payments-v1
webserver seine analytics 1 analytics-v1

# checkout — the Pod the policy attaches to
# audit    — an unselected Pod, so the policy's scope is provable
client seine checkout
client seine audit

kubectl apply -f - >/dev/null <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: payments
  namespace: seine
spec:
  selector:
    app: payments
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: analytics
  namespace: seine
spec:
  selector:
    app: analytics
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
EOF

waitdeploy seine payments
waitdeploy seine analytics
waitdeploy seine checkout
waitdeploy seine audit

# The answer needs a peer selector for the DNS pods, and every worked solution
# assumes kubeadm's label. Print what this cluster actually uses rather than
# leaving the student to discover a mismatch mid-question.
dnslabels=$(kubectl -n kube-system get pods -l k8s-app=kube-dns -o name 2>/dev/null | wc -l)
if [[ "$dnslabels" -gt 0 ]]; then
  echo "  (DNS pods carry k8s-app=kube-dns — $dnslabels of them; that is the peer label to select)"
else
  echo "  !! No pods matched k8s-app=kube-dns in kube-system. This cluster labels its"
  echo "     DNS pods differently — check before writing the egress rule:"
  kubectl -n kube-system get pods -l kubernetes.io/name=CoreDNS --show-labels 2>/dev/null \
    || kubectl -n kube-system get pods --show-labels 2>/dev/null | grep -i dns || true
fi

echo "READY q09 — seine has checkout+audit clients and payments+analytics Services, no NetworkPolicy yet (everything reaches everything)"
