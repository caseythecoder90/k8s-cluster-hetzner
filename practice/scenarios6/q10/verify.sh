#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q10:"

# The whole question hangs off two live Pod IPs. If a Pod was re-created the
# file is stale and every connectivity check below would lie, so bail early.
file_beta=$($SSH_CP "grep -E '^quarantined:' /course6/10/peers.txt 2>/dev/null | awk '{print \$2}' | cut -d/ -f1" || true)
cur_beta=$(kubectl -n thames get pod -l app=beta -o jsonpath='{.items[0].status.podIP}' 2>/dev/null || true)
cur_alpha=$(kubectl -n thames get pod -l app=alpha -o jsonpath='{.items[0].status.podIP}' 2>/dev/null || true)
[[ -n "$file_beta" ]] || { fail "/course6/10/peers.txt is missing or unreadable — re-run setup.sh"; exit 1; }
[[ "$file_beta" == "$cur_beta" ]] && pass "peers.txt still matches the live Pods (beta = $cur_beta)" \
  || { fail "peers.txt says beta is $file_beta but it is now $cur_beta — a Pod was re-created, so re-run setup.sh and redo the policy"; exit 1; }

$SSH_CP "test -f /course6/10/vault-ingress.yaml" && pass "policy saved at /course6/10/vault-ingress.yaml" || fail "/course6/10/vault-ingress.yaml is missing"

jp() { kubectl -n thames get netpol vault-ingress -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "NetworkPolicy vault-ingress exists" || { fail "no NetworkPolicy named vault-ingress in Namespace thames"; exit 1; }
[[ "$(jp '{.spec.podSelector.matchLabels.app}')" == "vault" ]] && pass "podSelector is app=vault" || fail "podSelector is '$(jp '{.spec.podSelector}')' (expected matchLabels app: vault)"
jp '{.spec.policyTypes[*]}' | grep -qw Ingress && pass "policyTypes includes Ingress" || fail "policyTypes is '$(jp '{.spec.policyTypes[*]}')'"
jp '{.spec.policyTypes[*]}' | grep -qw Egress  && fail "policyTypes includes Egress — this task governs Ingress only, and adding Egress would default-deny vault's own outbound traffic" || pass "policyTypes is Ingress only"

# --- forced mechanism: ipBlock, and only ipBlock ---
cidr=$(jp '{.spec.ingress[*].from[*].ipBlock.cidr}')
exc=$(jp '{.spec.ingress[*].from[*].ipBlock.except[*]}')
[[ -n "$cidr" ]] && pass "rule uses an ipBlock cidr ($cidr)" || fail "no ipBlock.cidr in the ingress rule — this question is about ipBlock, not selectors"
echo "$exc" | grep -qw -- "$cur_beta/32" && pass "except: carves out $cur_beta/32" || fail "ipBlock.except is '$exc' (expected it to contain $cur_beta/32) — except: is a field INSIDE ipBlock, a sibling of cidr:"
[[ -z "$(jp '{.spec.ingress[*].from[*].podSelector}')" ]] && pass "no podSelector in the rule" || fail "a podSelector is present — the task asks for the peers as a CIDR"
[[ -z "$(jp '{.spec.ingress[*].from[*].namespaceSelector}')" ]] && pass "no namespaceSelector in the rule" || fail "a namespaceSelector is present — the task asks for the peers as a CIDR"
[[ "$(jp '{.spec.ingress[*].ports[*].port}')" == "80" ]] && pass "rule is scoped to port 80" || fail "ingress ports is '$(jp '{.spec.ingress[*].ports[*].port}')' (expected 80)"

# --- outcome: permitted flows, forbidden is really blocked ---
vip=$(svcip thames vault)
[[ -n "$vip" ]] || { fail "Service vault is gone — re-run setup.sh"; exit 1; }
reach thames alpha "http://$vip" \
  && pass "alpha ($cur_alpha) still reaches vault" \
  || fail "alpha can no longer reach vault — is $cur_alpha really inside the cidr, and did an over-wide except: swallow it?"
reach thames beta "http://$vip" \
  && fail "beta ($cur_beta) still reaches vault — the except: entry is not taking effect" \
  || pass "beta is blocked from vault"

[[ "$(kubectl -n thames get deploy vault -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" == "1" ]] && pass "vault still ready" || fail "vault Deployment is not ready — it was not supposed to change"

exit ${FAILED}
