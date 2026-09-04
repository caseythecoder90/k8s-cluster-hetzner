#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q04:"
img=$(kubectl -n hermes get deploy hermes-canary -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[[ "$img" == "nginx:1.31-alpine" ]] && pass "canary image updated" || fail "canary image is '$img'"
rep=$(kubectl -n hermes get deploy hermes-canary -o jsonpath='{.spec.replicas}' 2>/dev/null)
[[ "$rep" == "1" ]] && pass "canary scaled to 1" || fail "canary replicas is '$rep'"
sel=$(kubectl -n hermes get svc hermes-svc -o jsonpath='{.spec.selector}' 2>/dev/null)
echo "$sel" | grep -q '"track"' && fail "selector was narrowed to a track — should stay app-only" || pass "selector untouched"
eps=$(kubectl -n hermes get endpointslices -l kubernetes.io/service-name=hermes-svc -o jsonpath='{.items[*].endpoints[*].targetRef.name}' 2>/dev/null)
stable=0; canary=0
for p in $eps; do [[ "$p" == hermes-stable-* ]] && stable=1; [[ "$p" == hermes-canary-* ]] && canary=1; done
[[ $stable == 1 && $canary == 1 ]] && pass "service reaches both stable and canary pods" || fail "service missing one track's endpoints"
exit ${FAILED}
