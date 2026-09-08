#!/bin/bash
# Shared helpers for scenario setup/verify scripts (Exam Set 6: Services, NetworkPolicy, traffic shifting).
# Usage in a scenario script:  source "$(dirname "$0")/../common.sh"
set -euo pipefail

SCENARIOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRACTICE_DIR="$(dirname "$SCENARIOS_DIR")"
COURSE=/course6

# Which lab cluster to talk to. "default" is the normal lab (terraform's default
# workspace, kubeconfig admin.conf). A second lab built in another Terraform
# workspace (see practice/README.md) is addressed by its workspace name:
#   LAB_WORKSPACE=hk ./setup-all.sh      # cluster lab-hk, kubeconfig admin-hk.conf
LAB_WORKSPACE="${LAB_WORKSPACE:-default}"
export TF_WORKSPACE="$LAB_WORKSPACE"
if [[ "$LAB_WORKSPACE" == "default" ]]; then
  export KUBECONFIG="$PRACTICE_DIR/ansible/kubeconfig/admin.conf"
else
  export KUBECONFIG="$PRACTICE_DIR/ansible/kubeconfig/admin-$LAB_WORKSPACE.conf"
fi

CP_IP=$(cd "$PRACTICE_DIR/terraform" && terraform output -raw control_plane_public_ip)
WORKER_IP=$(cd "$PRACTICE_DIR/terraform" && terraform output -raw worker_public_ip)

# Lab-only known_hosts: the lab is destroyed and rebuilt constantly, Hetzner
# recycles IPs, and a changed host key must never trip a real hosts file.
SSH_OPTS="-i $HOME/.ssh/hetzner_k8s -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$HOME/.ssh/known_hosts_lab -o LogLevel=ERROR"
SSH_CP="ssh $SSH_OPTS deploy@$CP_IP"
SSH_WORKER="ssh $SSH_OPTS deploy@$WORKER_IP"

# Guard: refuse to run against anything but a lab cluster
ctx=$(kubectl config current-context)
if [[ "$ctx" != *"lab"* ]]; then
  echo "REFUSING: kubectl context is '$ctx', not a lab cluster." >&2
  exit 1
fi

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }

# mkcourse $COURSE/7  — create a task's file-drop dir, owned by deploy
mkcourse() { $SSH_CP "sudo mkdir -p $1 && sudo chown -R deploy:deploy $1"; }

# nsensure ns1 ns2 ...  — create if missing, leave existing contents alone
nsensure() {
  for ns in "$@"; do
    kubectl get namespace "$ns" >/dev/null 2>&1 || kubectl create namespace "$ns" >/dev/null
  done
}

# nswipe ns1 ns2 ...  — delete and recreate namespaces so a re-run starts clean
nswipe() {
  for ns in "$@"; do
    kubectl delete namespace "$ns" --ignore-not-found --wait=true >/dev/null 2>&1 || true
    kubectl create namespace "$ns" >/dev/null
  done
}

# nsdelete ns1 ...  — delete without recreating, for questions where creating
# the Namespace is part of the task
nsdelete() {
  for ns in "$@"; do
    kubectl delete namespace "$ns" --ignore-not-found --wait=true >/dev/null 2>&1 || true
  done
}

# fingerprint <label> <remote files...>  — record a checksum of files a task
# says must not change (globs expand on the control plane).
fingerprint() { local l=$1; shift; $SSH_CP "sudo mkdir -p $COURSE/_check && sudo chown deploy:deploy $COURSE/_check && cat $* | md5sum | cut -d' ' -f1 > $COURSE/_check/$l.md5"; }
# unchanged <label> <remote files...>  — true if they still match
unchanged()   { local l=$1; shift; $SSH_CP "[[ \$(cat $* 2>/dev/null | md5sum | cut -d' ' -f1) == \$(cat $COURSE/_check/$l.md5) ]]"; }

# waitdeploy <ns> <deploy> [timeout]  — block until the rollout completes
waitdeploy() { kubectl -n "$1" rollout status "deploy/$2" --timeout="${3:-120s}" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# Connectivity probes. Every check drives a real Pod through the real CNI —
# Calico enforces NetworkPolicy in this lab, so "blocked" here means blocked.
# ---------------------------------------------------------------------------

# svcip <ns> <svc>  — the ClusterIP. Probes hit the IP, not the DNS name, so a
# broken-DNS question never turns every other check red by accident.
svcip() { kubectl -n "$1" get svc "$2" -o jsonpath='{.spec.clusterIP}' 2>/dev/null; }

# reach <ns> <deploy> <url>  — 0 when the client Pod can fetch it, 1 when not.
# A NetworkPolicy drop shows up as a connect timeout, hence -T.
reach() { kubectl -n "$1" exec "deploy/$2" -- wget -T 4 -q -O- "$3" >/dev/null 2>&1; }

# sample <ns> <deploy> <url> [n]  — fetch n times, print each body on its own
# line. Used to see which versions a Service is actually load-balancing to.
sample() {
  local n="${4:-40}"
  kubectl -n "$1" exec "deploy/$2" -- sh -c \
    "for i in \$(seq 1 $n); do wget -T 3 -qO- $3 2>/dev/null; echo; done" 2>/dev/null
}

# webserver <ns> <name> <replicas> <body> [extra-pod-labels...]
# One nginx Deployment whose page is its own identity, so a probe can tell
# which Pod answered. No ConfigMap needed — the container writes its own page.
webserver() {
  local ns=$1 name=$2 reps=$3 body=$4; shift 4
  local labels="    app: $name"
  for kv in "$@"; do labels="$labels
    ${kv%%=*}: ${kv#*=}"; done
  kubectl apply -f - >/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
  namespace: $ns
spec:
  replicas: $reps
  selector:
    matchLabels:
      app: $name
  template:
    metadata:
      labels:
$labels
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          command: ["/bin/sh","-c","echo $body > /usr/share/nginx/html/index.html && exec nginx -g 'daemon off;'"]
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
}

# client <ns> <name> [pod-labels...]  — a long-lived busybox to probe from.
# Long-lived (not `kubectl run --rm`) so it carries stable labels for policies
# to select on, and so a probe costs an exec instead of a Pod start.
client() {
  local ns=$1 name=$2; shift 2
  local labels="    app: $name"
  for kv in "$@"; do labels="$labels
    ${kv%%=*}: ${kv#*=}"; done
  kubectl apply -f - >/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
  namespace: $ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $name
  template:
    metadata:
      labels:
$labels
    spec:
      containers:
        - name: probe
          image: busybox:1
          command: ["sh","-c","sleep 86400"]
          resources:
            requests: {cpu: 5m, memory: 8Mi}
EOF
}
