#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q11:"

$SSH_CP "test -f /course6/11/api-fence.yaml" && pass "policy saved at /course6/11/api-fence.yaml" || fail "/course6/11/api-fence.yaml is missing"

n=$(kubectl -n tiber get netpol -o name 2>/dev/null | wc -l | tr -d ' ')
[[ "$n" == "1" ]] && pass "exactly one NetworkPolicy in tiber" || fail "$n NetworkPolicies in tiber — the task asks for one policy covering both directions"

jp() { kubectl -n tiber get netpol api-fence -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "NetworkPolicy api-fence exists" || { fail "no NetworkPolicy named api-fence in Namespace tiber"; exit 1; }
[[ "$(jp '{.spec.podSelector.matchLabels.app}')" == "api" ]] && pass "podSelector is app=api" || fail "podSelector is '$(jp '{.spec.podSelector}')' (expected matchLabels app: api)"

pt=$(jp '{.spec.policyTypes[*]}')
echo "$pt" | grep -qw Ingress && pass "policyTypes includes Ingress" || fail "policyTypes is '$pt' — Ingress is missing, so inbound traffic is not governed at all"
echo "$pt" | grep -qw Egress  && pass "policyTypes includes Egress"  || fail "policyTypes is '$pt' — Egress is missing, so the egress: block below it is being ignored"
[[ -n "$(jp '{.spec.ingress[*]}')" ]] && pass "an ingress rule is present" || fail "policyTypes names Ingress but there is no ingress: rule — that combination denies ALL inbound traffic to api"
[[ -n "$(jp '{.spec.egress[*]}')" ]]  && pass "an egress rule is present"  || fail "policyTypes names Egress but there is no egress: rule — that combination denies ALL outbound traffic from api"

aip=$(svcip tiber api)
lip=$(svcip tiber logs)
bip=$(svcip tiber billing)
[[ -n "$aip" && -n "$lip" && -n "$bip" ]] || { fail "one of the Services api/logs/billing is gone — re-run setup.sh"; exit 1; }

# --- inbound: allowed source in, denied source out ---
reach tiber frontend "http://$aip" \
  && pass "frontend reaches api (ingress allow works)" \
  || fail "frontend cannot reach api at $aip — check the ingress from: peer (app=frontend) and port 80"
reach tiber scanner "http://$aip" \
  && fail "scanner still reaches api at $aip — the ingress rule is too wide" \
  || pass "scanner is blocked from api"

# --- outbound: allowed destination reachable, denied destination not ---
reach tiber api "http://$lip" \
  && pass "api reaches logs (egress allow works)" \
  || fail "api cannot reach logs at $lip — listing Egress in policyTypes default-denies outbound, so an egress: rule to app=logs on TCP 80 is required"
reach tiber api "http://$bip" \
  && fail "api still reaches billing at $bip — the egress rule is too wide, or Egress never made it into policyTypes" \
  || pass "api is blocked from billing"

# --- the policy is scoped to api and nothing else ---
reach tiber frontend "http://$bip" && pass "frontend still reaches billing (unselected pods untouched)" || fail "frontend lost access to billing — the podSelector is catching pods it should not"
reach tiber scanner  "http://$lip" && pass "scanner still reaches logs (unselected pods untouched)"     || fail "scanner lost access to logs — the podSelector is catching pods it should not"

for d in api logs billing; do
  [[ "$(kubectl -n tiber get deploy "$d" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" == "1" ]] \
    && pass "$d still ready" || fail "$d Deployment is not ready — it was not supposed to change"
done

exit ${FAILED}
