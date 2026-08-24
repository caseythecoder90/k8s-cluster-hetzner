#!/bin/bash
# Print a base64-encoded kubeconfig for the ci-deployer ServiceAccount in a
# namespace. Paste the output into the repo's GitHub secret KUBE_CONFIG.
#
#   ./scripts/gen-ci-kubeconfig.sh personal-website
#   ./scripts/gen-ci-kubeconfig.sh grindtrack
#
# Requires your admin KUBECONFIG to be active (kubectl config current-context
# should say kubernetes-admin@prod).
set -euo pipefail

NS="${1:?usage: $0 <namespace>}"
SECRET="ci-deployer-token"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ctx=$(kubectl config current-context)
[[ "$ctx" == *prod* ]] || { echo "REFUSING: context is '$ctx', expected prod" >&2; exit 1; }

# Public IP so GitHub's runners can reach the API server (it is in the cert SANs)
SERVER="https://$(cd "$REPO_ROOT/terraform" && terraform output -raw control_plane_public_ip):6443"

CA=$(kubectl -n "$NS" get secret "$SECRET" -o jsonpath='{.data.ca\.crt}')
TOKEN=$(kubectl -n "$NS" get secret "$SECRET" -o jsonpath='{.data.token}' | base64 -d)

[[ -n "$CA" && -n "$TOKEN" ]] || { echo "token secret not populated yet — wait a moment and retry" >&2; exit 1; }

cat <<EOF | base64 -w0
apiVersion: v1
kind: Config
clusters:
  - name: prod
    cluster:
      server: ${SERVER}
      certificate-authority-data: ${CA}
contexts:
  - name: ci
    context:
      cluster: prod
      namespace: ${NS}
      user: ci-deployer
current-context: ci
users:
  - name: ci-deployer
    user:
      token: ${TOKEN}
EOF
echo
