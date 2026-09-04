#!/bin/bash
# Shared helpers for scenario setup/verify scripts (Exam Set 2).
# Usage in a scenario script:  source "$(dirname "$0")/../common.sh"
set -euo pipefail

SCENARIOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRACTICE_DIR="$(dirname "$SCENARIOS_DIR")"

export KUBECONFIG="$PRACTICE_DIR/ansible/kubeconfig/admin.conf"

CP_IP=$(cd "$PRACTICE_DIR/terraform" && terraform output -raw control_plane_public_ip)
WORKER_IP=$(cd "$PRACTICE_DIR/terraform" && terraform output -raw worker_public_ip)
SSH_CP="ssh -i $HOME/.ssh/hetzner_k8s deploy@$CP_IP"

# Guard: refuse to run against anything but the lab
ctx=$(kubectl config current-context)
if [[ "$ctx" != *"lab"* ]]; then
  echo "REFUSING: kubectl context is '$ctx', not the lab cluster." >&2
  exit 1
fi

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }
