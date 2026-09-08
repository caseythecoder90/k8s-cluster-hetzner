#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q15:"

sjp() { kubectl -n congo get svc feed -o jsonpath="$1" 2>/dev/null; }
djp() { kubectl -n congo get deploy feed-primary -o jsonpath="$1" 2>/dev/null; }

# --- the Service is the thing that must NOT have moved ---
[[ -n "$(sjp '{.metadata.name}')" ]] && pass "Service feed still exists" || { fail "Service feed is gone — a promotion never touches the Service"; exit 1; }
[[ "$(sjp '{.spec.selector}')" == '{"tier":"feed"}' ]] && pass "Service selector is still exactly tier=feed" || fail "Service feed selector is '$(sjp '{.spec.selector}')' — it must stay tier: feed; the shared label is what makes the promotion seamless"
[[ "$(sjp '{.spec.ports[0].port}')" == "80" ]] && pass "Service port still 80" || fail "Service port is '$(sjp '{.spec.ports[0].port}')'"

# --- the canary is gone ---
kubectl -n congo get deploy feed-canary >/dev/null 2>&1 \
  && fail "Deployment feed-canary still exists — the last step of a promotion is deleting it" \
  || pass "Deployment feed-canary deleted"
ncan=$(kubectl -n congo get pod -l app=feed-canary -o name 2>/dev/null | wc -l | tr -d ' ')
[[ "$ncan" == "0" ]] && pass "no canary Pods left" || fail "$ncan canary Pods are still running"

# --- the primary carries the new version, at the new size, with the shared label ---
[[ -n "$(djp '{.metadata.name}')" ]] && pass "Deployment feed-primary still exists" || { fail "feed-primary is gone — promoting means rolling the primary forward, not replacing it with the canary"; exit 1; }
[[ "$(djp '{.spec.replicas}')" == "4" ]] && pass "feed-primary declares 4 replicas" || fail "feed-primary replicas is '$(djp '{.spec.replicas}')' (expected 4)"
[[ "$(djp '{.status.readyReplicas}')" == "4" ]] && pass "feed-primary has 4 ready Pods" || fail "feed-primary has '$(djp '{.status.readyReplicas}')' ready Pods (expected 4)"
[[ "$(djp '{.status.updatedReplicas}')" == "4" ]] && pass "rollout complete (4 updated)" || fail "only '$(djp '{.status.updatedReplicas}')' Pods are on the new template — the rollout has not finished"
[[ "$(djp '{.spec.template.metadata.labels.tier}')" == "feed" ]] && pass "primary pod template keeps tier=feed" || fail "primary pod template has no tier=feed — the Service selects that label, so the whole app would go dark"
[[ "$(djp '{.spec.template.metadata.labels.version}')" == "v2" ]] && pass "primary pod template is version=v2" || fail "primary pod template version is '$(djp '{.spec.template.metadata.labels.version}')' (expected v2)"
djp '{.spec.template.spec.containers[0].command}' | grep -q 'feed-v2' && pass "primary container serves feed-v2" || fail "primary's container still serves '$(djp '{.spec.template.spec.containers[0].command}')'"

# --- the Service is backed by the 4 primary Pods and nothing else ---
pips=" $(kubectl -n congo get pod -l app=feed-primary -o jsonpath='{.items[*].status.podIP}' 2>/dev/null) "
eps=$(kubectl -n congo get endpoints feed -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
nep=$(echo "$eps" | wc -w | tr -d ' ')
[[ "$nep" == "4" ]] && pass "Service feed has 4 Endpoints" || fail "Service feed has $nep Endpoints (expected 4)"
bad=0
for ip in $eps; do echo "$pips" | grep -q " $ip " || bad=1; done
[[ "$bad" == "0" && "$nep" != "0" ]] && pass "every Endpoint is a feed-primary Pod" || fail "Service feed has Endpoints that are not feed-primary Pods ($eps)"

# --- outcome: 100% of the traffic is the new version ---
vip=$(svcip congo feed)
[[ -n "$vip" ]] || { fail "Service feed has no ClusterIP"; exit 1; }
out=$(sample congo probe "http://$vip" 30 | grep -v '^[[:space:]]*$' || true)
n_all=$(printf '%s\n' "$out" | grep -c . || true)
n_v1=$(printf '%s\n' "$out" | grep -c '^feed-v1$' || true)
n_v2=$(printf '%s\n' "$out" | grep -c '^feed-v2$' || true)
[[ "$n_all" -ge 26 ]] && pass "$n_all/30 requests answered" || fail "only $n_all/30 requests answered — the Service lost its backing Pods"
[[ "$n_v1" == "0" ]] && pass "no response came from the old version" || fail "$n_v1/$n_all responses were feed-v1 — some primary Pods are still on the old template"
[[ "$n_v2" == "$n_all" && "$n_v2" -ge 26 ]] && pass "all $n_v2 responses are feed-v2" || fail "only $n_v2/$n_all responses were feed-v2"

exit ${FAILED}
