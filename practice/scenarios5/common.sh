#!/bin/bash
# Shared helpers for scenario setup/verify scripts (Exam Set 5: Kustomize, cold).
# Usage in a scenario script:  source "$(dirname "$0")/../common.sh"
set -euo pipefail

SCENARIOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRACTICE_DIR="$(dirname "$SCENARIOS_DIR")"
COURSE=/course5

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

# waitdeploy <ns> <deploy> [timeout]  — block until the rollout completes.
# A bare number is accepted and read as seconds: kubectl --timeout demands a
# unit and rejects "90", which would otherwise fail silently behind a || true.
waitdeploy() {
  local t="${3:-120s}"
  [[ "$t" =~ ^[0-9]+$ ]] && t="${t}s"
  kubectl -n "$1" rollout status "deploy/$2" --timeout="$t" >/dev/null 2>&1
}
