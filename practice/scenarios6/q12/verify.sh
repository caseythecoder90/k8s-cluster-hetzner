#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q12:"

sjp() { kubectl -n volga get svc checkout -o jsonpath="$1" 2>/dev/null; }
djp() { kubectl -n volga get deploy "$1" -o jsonpath="$2" 2>/dev/null; }

[[ -n "$(sjp '{.metadata.name}')" ]] && pass "Service checkout still exists" || { fail "Service checkout is gone — the cutover is a selector change, not a delete-and-recreate"; exit 1; }
[[ "$(sjp '{.spec.type}')" == "ClusterIP" ]] && pass "Service is still ClusterIP" || fail "Service type is '$(sjp '{.spec.type}')' (expected ClusterIP)"
[[ "$(sjp '{.spec.ports[0].port}')" == "80" ]] && pass "Service port still 80" || fail "Service port is '$(sjp '{.spec.ports[0].port}')' (expected 80)"

# --- blue must be intact and ready to take traffic back ---
[[ "$(djp checkout-blue '{.spec.replicas}')" == "3" ]] && pass "checkout-blue still declares 3 replicas" || fail "checkout-blue replicas is '$(djp checkout-blue '{.spec.replicas}')' — scaling blue down is not a cutover, it destroys the rollback"
[[ "$(djp checkout-blue '{.status.readyReplicas}')" == "3" ]] && pass "checkout-blue has 3 ready Pods" || fail "checkout-blue has '$(djp checkout-blue '{.status.readyReplicas}')' ready Pods (expected 3)"
djp checkout-blue '{.spec.template.spec.containers[0].command}' | grep -q 'blue-v1' && pass "checkout-blue still serves blue-v1" || fail "checkout-blue's container was edited — blue must be left exactly as it was"
[[ "$(djp checkout-green '{.spec.replicas}')" == "3" ]] && pass "checkout-green still declares 3 replicas" || fail "checkout-green replicas is '$(djp checkout-green '{.spec.replicas}')' (expected 3)"
[[ "$(djp checkout-green '{.status.readyReplicas}')" == "3" ]] && pass "checkout-green has 3 ready Pods" || fail "checkout-green has '$(djp checkout-green '{.status.readyReplicas}')' ready Pods (expected 3)"

# --- the Service must now be backed by green Pods and only green Pods ---
greenips=" $(kubectl -n volga get pod -l track=green -o jsonpath='{.items[*].status.podIP}' 2>/dev/null) "
eps=$(kubectl -n volga get endpoints checkout -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
nep=$(echo "$eps" | wc -w | tr -d ' ')
[[ "$nep" == "3" ]] && pass "Service has 3 Endpoints" || fail "Service checkout has $nep Endpoints (expected 3, the green Pods) — a selector that matches nothing leaves it empty"
bad=0
for ip in $eps; do echo "$greenips" | grep -q " $ip " || bad=1; done
[[ "$bad" == "0" && "$nep" != "0" ]] && pass "every Endpoint is a green Pod" || fail "Service checkout still has non-green Endpoints ($eps) — the selector must match green only"

# --- outcome: every sampled response comes from green ---
cip=$(svcip volga checkout)
[[ -n "$cip" ]] || { fail "Service checkout has no ClusterIP"; exit 1; }
out=$(sample volga probe "http://$cip" 24 | grep -v '^[[:space:]]*$' || true)
n_all=$(printf '%s\n' "$out"  | grep -c . || true)
n_green=$(printf '%s\n' "$out" | grep -c '^green-v2$' || true)
n_blue=$(printf '%s\n' "$out"  | grep -c '^blue-v1$' || true)
[[ "$n_all" -ge 20 ]] && pass "$n_all/24 requests answered" || fail "only $n_all/24 requests answered — the Service is not serving"
[[ "$n_blue" == "0" ]] && pass "no response came from blue" || fail "$n_blue/$n_all responses were blue-v1 — the cutover is partial, the Service is still matching blue Pods"
[[ "$n_green" == "$n_all" && "$n_green" -ge 20 ]] && pass "all $n_green responses came from green" || fail "only $n_green/$n_all responses were green-v2"

exit ${FAILED}
