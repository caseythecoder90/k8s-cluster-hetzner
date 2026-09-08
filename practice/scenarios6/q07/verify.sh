#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q07:"

podip() { kubectl -n "$1" get pod -l "$2" -o jsonpath='{.items[0].status.podIP}' 2>/dev/null || true; }

$SSH_CP "test -s /course6/7/policy.yaml" && pass "/course6/7/policy.yaml saved" || fail "/course6/7/policy.yaml is missing or empty — the task asks for the manifest on disk"

np=$(kubectl -n mekong get netpol allow-from-nile -o json 2>/dev/null || true)
[[ -n "$np" ]] && pass "NetworkPolicy allow-from-nile exists in mekong" || { fail "no NetworkPolicy 'allow-from-nile' in Namespace mekong"; exit 1; }

echo "$np" | grep -q "namespaceSelector" && pass "the rule uses a namespaceSelector" || fail "no namespaceSelector in the policy — a podSelector alone cannot see across a Namespace boundary"
echo "$np" | tr -d ' \n' | grep -q '"kubernetes.io/metadata.name":"nile"' \
  && pass "nile is selected by its automatic kubernetes.io/metadata.name label" \
  || fail "the policy does not select the Namespace with kubernetes.io/metadata.name=nile — that label is set on every Namespace for you, and the task forbids adding your own"

dbip=$(podip mekong app=mekong-db)
[[ -n "$dbip" ]] && pass "mekong-db Pod has an IP ($dbip)" || { fail "no Running mekong-db Pod found — re-run setup.sh"; exit 1; }

reach nile nile-client "http://$dbip:80" \
  && pass "allowed: nile-client (Namespace nile) reaches mekong-db" \
  || fail "nile-client cannot reach $dbip:80 — is the namespaceSelector value really 'nile', and is the port 80?"

reach nile nile-batch "http://$dbip:80" \
  && pass "allowed: nile-batch reaches it too — ANY Pod in nile" \
  || fail "nile-batch is blocked, but the task says any Pod in nile gets in — you have narrowed the rule with a podSelector as well"

reach mekong mekong-client "http://$dbip:80" \
  && fail "mekong-client STILL reaches $dbip:80 — it carries the same role=client label as nile-client, so a podSelector-based rule lets in the wrong one; the Namespace is what separates them" \
  || pass "blocked: mekong-client cannot reach mekong-db despite identical labels"

exit ${FAILED}
