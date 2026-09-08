#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q13:"

sjp() { kubectl -n yangtze get svc "$1" -o jsonpath="$2" 2>/dev/null; }
djp() { kubectl -n yangtze get deploy "$1" -o jsonpath="$2" 2>/dev/null; }

# --- both environments still standing: that is what makes the rollback instant ---
for d in orders-blue orders-green; do
  [[ "$(djp "$d" '{.spec.replicas}')" == "2" ]] && pass "$d still declares 2 replicas" || fail "$d replicas is '$(djp "$d" '{.spec.replicas}')' — neither Deployment may be scaled"
  [[ "$(djp "$d" '{.status.readyReplicas}')" == "2" ]] && pass "$d has 2 ready Pods" || fail "$d has '$(djp "$d" '{.status.readyReplicas}')' ready Pods (expected 2)"
done
djp orders-blue  '{.spec.template.spec.containers[0].command}' | grep -q 'orders-v1' && pass "orders-blue still serves orders-v1"  || fail "orders-blue's container was edited"
djp orders-green '{.spec.template.spec.containers[0].command}' | grep -q 'orders-v2' && pass "orders-green still serves orders-v2" || fail "orders-green's container was edited"

# --- step 1: the test Service exists and reaches green only ---
[[ -n "$(sjp orders-test '{.metadata.name}')" ]] && pass "Service orders-test exists" || { fail "no Service named orders-test in yangtze — green needs its own way in while blue keeps serving"; exit 1; }
[[ "$(sjp orders-test '{.spec.type}')" == "ClusterIP" ]] && pass "orders-test is ClusterIP" || fail "orders-test type is '$(sjp orders-test '{.spec.type}')' (expected ClusterIP)"
[[ "$(sjp orders-test '{.spec.ports[0].port}')" == "80" ]] && pass "orders-test port 80" || fail "orders-test port is '$(sjp orders-test '{.spec.ports[0].port}')' (expected 80)"
[[ "$(sjp orders-test '{.spec.ports[0].targetPort}')" == "80" ]] && pass "orders-test targetPort 80" || fail "orders-test targetPort is '$(sjp orders-test '{.spec.ports[0].targetPort}')' (expected 80)"

greenips=" $(kubectl -n yangtze get pod -l track=green -o jsonpath='{.items[*].status.podIP}' 2>/dev/null) "
blueips=" $(kubectl -n yangtze get pod -l track=blue  -o jsonpath='{.items[*].status.podIP}' 2>/dev/null) "

epcheck() { # epcheck <svc> <allowed-ip-list> <expected-count> <label>
  local eps n bad=0 ip
  eps=$(kubectl -n yangtze get endpoints "$1" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
  n=$(echo "$eps" | wc -w | tr -d ' ')
  for ip in $eps; do echo "$2" | grep -q " $ip " || bad=1; done
  [[ "$n" == "$3" && "$bad" == "0" ]] && pass "Service $1 has $3 Endpoints, all $4" \
    || fail "Service $1 Endpoints are '$eps' ($n of them) — expected $3, all $4"
}
epcheck orders-test "$greenips" 2 "green Pods"
epcheck orders      "$blueips"  2 "blue Pods"

# --- step 3: the cutover was actually performed ---
cut=$($SSH_CP "cat /course6/13/cutover.txt 2>/dev/null" || true)
[[ -n "$cut" ]] && pass "/course6/13/cutover.txt exists" || fail "/course6/13/cutover.txt is missing or empty — it is the only proof the cutover happened before the rollback"
echo "$cut" | grep -q 'green' && pass "cutover.txt records Service orders selecting green" || fail "cutover.txt is '$cut' — it must have been captured while orders was pointing at green, not before or after"

# --- step 4: end state, sampled ---
oip=$(svcip yangtze orders)
tip=$(svcip yangtze orders-test)
[[ -n "$oip" && -n "$tip" ]] || { fail "orders or orders-test has no ClusterIP"; exit 1; }

o=$(sample yangtze probe "http://$oip" 20 | grep -v '^[[:space:]]*$' || true)
o_all=$(printf '%s\n' "$o" | grep -c . || true)
o_v1=$(printf '%s\n' "$o" | grep -c '^orders-v1$' || true)
o_v2=$(printf '%s\n' "$o" | grep -c '^orders-v2$' || true)
[[ "$o_all" -ge 17 ]] && pass "orders answered $o_all/20 requests" || fail "orders answered only $o_all/20 requests"
[[ "$o_v2" == "0" ]] && pass "no response on orders came from green" || fail "$o_v2/$o_all responses on orders were orders-v2 — the rollback did not land"
[[ "$o_v1" == "$o_all" && "$o_v1" -ge 17 ]] && pass "orders is back on blue ($o_v1 x orders-v1)" || fail "only $o_v1/$o_all responses on orders were orders-v1"

t=$(sample yangtze probe "http://$tip" 12 | grep -v '^[[:space:]]*$' || true)
t_all=$(printf '%s\n' "$t" | grep -c . || true)
t_v2=$(printf '%s\n' "$t" | grep -c '^orders-v2$' || true)
[[ "$t_all" -ge 10 ]] && pass "orders-test answered $t_all/12 requests" || fail "orders-test answered only $t_all/12 requests"
[[ "$t_v2" == "$t_all" && "$t_v2" -ge 10 ]] && pass "orders-test serves green only ($t_v2 x orders-v2)" || fail "only $t_v2/$t_all responses on orders-test were orders-v2 — it must select green and nothing else"

exit ${FAILED}
