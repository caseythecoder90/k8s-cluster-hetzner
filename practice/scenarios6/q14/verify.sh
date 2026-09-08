#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q14:"

sjp() { kubectl -n zambezi get svc shop -o jsonpath="$1" 2>/dev/null; }
djp() { kubectl -n zambezi get deploy "$1" -o jsonpath="$2" 2>/dev/null; }

# --- the Service is the fixed point of a canary: it never changes ---
[[ "$(sjp '{.spec.selector.tier}')" == "shop" ]] && pass "Service shop still selects tier=shop" || fail "Service shop selector is '$(sjp '{.spec.selector}')' — it must stay exactly tier: shop"
[[ "$(sjp '{.spec.selector}')" == '{"tier":"shop"}' ]] && pass "Service selector is unchanged" || fail "Service shop selector is '$(sjp '{.spec.selector}')' (expected only tier: shop) — the split is made with replica counts, never by editing the Service"
[[ "$(sjp '{.spec.ports[0].port}')" == "80" ]] && pass "Service port still 80" || fail "Service port is '$(sjp '{.spec.ports[0].port}')'"

# --- both Deployments, at the computed ratio ---
[[ -n "$(djp shop-canary '{.metadata.name}')" ]] && pass "Deployment shop-canary exists" || { fail "no Deployment shop-canary — apply /course6/14/shop-canary.yaml"; exit 1; }
[[ "$(djp shop-primary '{.status.readyReplicas}')" == "6" ]] && pass "shop-primary has 6 ready Pods" || fail "shop-primary has '$(djp shop-primary '{.status.readyReplicas}')' ready Pods — 8 pods total with ~25% on the canary means 6 primary"
[[ "$(djp shop-canary  '{.status.readyReplicas}')" == "2" ]] && pass "shop-canary has 2 ready Pods"  || fail "shop-canary has '$(djp shop-canary '{.status.readyReplicas}')' ready Pods — 2 of 8 is the ~25% slice"

# --- the canary must not have been made to fight the primary for pods ---
[[ "$(djp shop-canary '{.spec.selector.matchLabels.app}')" == "shop-canary" ]] \
  && pass "shop-canary still owns only its own pods (selector app=shop-canary)" \
  || fail "shop-canary's spec.selector is '$(djp shop-canary '{.spec.selector.matchLabels}')' — putting the SHARED label in a Deployment's own selector makes the two Deployments try to adopt each other's pods"
[[ "$(djp shop-canary '{.spec.template.metadata.labels.version}')" == "v2" ]] && pass "canary pods still labelled version=v2" || fail "canary pod template lost version=v2 — that label is how you tell the two apart"
[[ "$(djp shop-canary '{.spec.template.metadata.labels.tier}')" == "shop" ]] && pass "canary pods carry the shared label tier=shop" || fail "canary pod template has no tier=shop — the Service selects that label, so without it the canary gets no traffic at all"
[[ "$(djp shop-primary '{.spec.template.metadata.labels.tier}')" == "shop" ]] && pass "primary pods still carry tier=shop" || fail "primary pod template lost tier=shop"

# --- Endpoints must include pods from BOTH Deployments ---
eps=" $(kubectl -n zambezi get endpoints shop -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null) "
nep=$(echo "$eps" | wc -w | tr -d ' ')
[[ "$nep" == "8" ]] && pass "Service shop has 8 Endpoints" || fail "Service shop has $nep Endpoints (expected 8)"
pip=$(kubectl -n zambezi get pod -l app=shop-primary -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)
cip=$(kubectl -n zambezi get pod -l app=shop-canary  -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)
[[ -n "$pip" ]] && echo "$eps" | grep -q " $pip " && pass "a shop-primary Pod is in the Endpoints" || fail "no shop-primary Pod IP in the Endpoints of Service shop"
[[ -n "$cip" ]] && echo "$eps" | grep -q " $cip " && pass "a shop-canary Pod is in the Endpoints"  || fail "no shop-canary Pod IP in the Endpoints of Service shop — the shared label is missing from the canary's pod template"

# --- outcome: both versions actually answer. kube-proxy picks a backend at
# --- random, so the assertion is "both appear", never an exact percentage.
vip=$(svcip zambezi shop)
[[ -n "$vip" ]] || { fail "Service shop has no ClusterIP"; exit 1; }
out=$(sample zambezi probe "http://$vip" 60 | grep -v '^[[:space:]]*$' || true)
n_all=$(printf '%s\n' "$out" | grep -c . || true)
n_v1=$(printf '%s\n' "$out" | grep -c '^shop-v1$' || true)
n_v2=$(printf '%s\n' "$out" | grep -c '^shop-v2$' || true)
[[ "$n_all" -ge 50 ]] && pass "$n_all/60 requests answered" || fail "only $n_all/60 requests answered — the Service is not serving properly"
[[ "$n_v1" -ge 1 ]] && pass "shop-v1 answered $n_v1/$n_all requests" || fail "the primary never answered in $n_all requests"
[[ "$n_v2" -ge 1 ]] && pass "shop-v2 answered $n_v2/$n_all requests" || fail "the canary never answered in $n_all requests — its pods are not behind the Service"

exit ${FAILED}
