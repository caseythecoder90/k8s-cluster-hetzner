#!/bin/bash
# Shared helpers for scenario setup/verify scripts (Exam Set 4: Helm + Kustomize).
# Usage in a scenario script:  source "$(dirname "$0")/../common.sh"
set -euo pipefail

SCENARIOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRACTICE_DIR="$(dirname "$SCENARIOS_DIR")"

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

# mkcourse /course4/7  — create a task's file-drop dir, owned by deploy
mkcourse() { $SSH_CP "sudo mkdir -p $1 && sudo chown -R deploy:deploy $1"; }

# nsensure ns1 ns2 ...  — create if missing, leave existing contents alone
nsensure() {
  for ns in "$@"; do
    kubectl get namespace "$ns" >/dev/null 2>&1 || kubectl create namespace "$ns" >/dev/null
  done
}

# nswipe ns1 ns2 ...  — delete and recreate namespaces so a re-run starts clean.
# Helm releases live in their Namespace (as Secrets), so this wipes them too.
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
fingerprint() { local l=$1; shift; $SSH_CP "sudo mkdir -p /course4/_check && sudo chown deploy:deploy /course4/_check && cat $* | md5sum | cut -d' ' -f1 > /course4/_check/$l.md5"; }
# unchanged <label> <remote files...>  — true if they still match
unchanged()   { local l=$1; shift; $SSH_CP "[[ \$(cat $* 2>/dev/null | md5sum | cut -d' ' -f1) == \$(cat /course4/_check/$l.md5) ]]"; }

# helm_value <ns> <release> <dotted.path>  — one user-supplied value of a
# release, printed as text. YAML quoting is not significant here: a values file
# may legitimately write `nodePort: "30402"` (the chart's own default for that
# key is an empty string) or `nodePort: 30402`, and both come back as 30402.
# That is why this parses the JSON instead of grepping it.
helm_value() {
  $SSH_CP "helm -n $1 get values $2 -o json 2>/dev/null" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for k in sys.argv[1].split("."):
    if not isinstance(d, dict) or k not in d:
        sys.exit(0)
    d = d[k]
print(d)
' "$3" 2>/dev/null || true
}

# helm_field <ns> <release> <field>  — one column of `helm ls -a` for one
# release: status | chart | revision | app_version. Empty if the release is gone.
helm_field() {
  $SSH_CP "helm -n $1 ls -a -o json 2>/dev/null" \
    | python3 -c "import sys,json; print(next((r['$3'] for r in json.load(sys.stdin) if r['name']=='$2'), ''))" 2>/dev/null || true
}

# Everything Helm-related runs on the control plane, where helm lives.
source "$SCENARIOS_DIR/lib/helm-repo.sh"
