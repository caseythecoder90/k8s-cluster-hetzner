#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q09:"

# A name lookup that has been firewalled off does not fail fast — the resolver
# walks the whole search path first — so the DNS probes get a hard wall clock
# limit instead of using reach()'s socket timeout.
nsx()   { timeout 25 kubectl -n seine exec deploy/"$1" -- nslookup "$2" >/dev/null 2>&1; }
getx()  { timeout 35 kubectl -n seine exec deploy/"$1" -- wget -T 5 -q -O- "$2" >/dev/null 2>&1; }

$SSH_CP "test -f /course6/9/egress.yaml" && pass "policy saved at /course6/9/egress.yaml" || fail "/course6/9/egress.yaml is missing"

jp() { kubectl -n seine get netpol checkout-egress -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "NetworkPolicy checkout-egress exists" || { fail "no NetworkPolicy named checkout-egress in Namespace seine"; exit 1; }
[[ "$(jp '{.spec.podSelector.matchLabels.app}')" == "checkout" ]] && pass "podSelector is app=checkout" || fail "podSelector is '$(jp '{.spec.podSelector}')' (expected matchLabels app: checkout)"
jp '{.spec.policyTypes[*]}' | grep -qw Egress  && pass "policyTypes includes Egress" || fail "policyTypes is '$(jp '{.spec.policyTypes[*]}')' — an egress: block does nothing until Egress is listed here"
jp '{.spec.policyTypes[*]}' | grep -qw Ingress && fail "policyTypes includes Ingress — this task governs Egress only" || pass "policyTypes is Egress only"

pip=$(svcip seine payments)
aip=$(svcip seine analytics)
[[ -n "$pip" && -n "$aip" ]] || { fail "Service payments or analytics is gone — re-run setup.sh"; exit 1; }

# --- DNS must survive the policy. This is the whole question. ---
nsx checkout payments.seine.svc.cluster.local \
  && pass "checkout still resolves payments.seine.svc.cluster.local" \
  || fail "DNS lookup from checkout fails — selecting a pod for Egress default-denies port 53 to kube-dns until the policy allows it (UDP and TCP 53 to the k8s-app=kube-dns pods in kube-system)"

getx checkout "http://payments.seine.svc.cluster.local" \
  && pass "checkout fetches payments BY NAME" \
  || fail "checkout cannot fetch http://payments.seine.svc.cluster.local — that is a name, so this needs BOTH the payments rule and the DNS rule"

# --- permitted traffic flows ---
reach seine checkout "http://$pip" \
  && pass "checkout reaches payments by ClusterIP ($pip)" \
  || fail "checkout cannot reach payments at $pip at all — the egress rule to the payments pods on TCP 80 is missing or mis-selected"

# --- forbidden traffic is actually blocked ---
reach seine checkout "http://$aip" \
  && fail "checkout still reaches analytics at $aip — the egress rule is too wide (a bare 'to: []' or an allow-all DNS rule that forgot to scope its ports)" \
  || pass "checkout is blocked from analytics"

# --- the policy is scoped to checkout and nothing else ---
reach seine audit "http://$aip" \
  && pass "audit (not selected) still reaches analytics" \
  || fail "audit lost access to analytics — the podSelector must select app=checkout only, not {}"
reach seine audit "http://$pip" \
  && pass "audit still reaches payments" \
  || fail "audit lost access to payments — the podSelector is catching more pods than it should"

[[ "$(kubectl -n seine get deploy payments  -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" == "1" ]] && pass "payments still ready"  || fail "payments Deployment is not ready — it was not supposed to change"
[[ "$(kubectl -n seine get deploy analytics -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" == "1" ]] && pass "analytics still ready" || fail "analytics Deployment is not ready — it was not supposed to change"

exit ${FAILED}
