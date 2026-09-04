#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q14:"
ci=$(kubectl -n olympus get svc olympus-svc -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
[[ "$ci" == "None" ]] && pass "service is headless (clusterIP: None)" || fail "clusterIP is '$ci'"
sn=$(kubectl -n olympus get statefulset olympus-app -o jsonpath='{.spec.serviceName}' 2>/dev/null)
[[ "$sn" == "olympus-svc" ]] && pass "statefulset.serviceName correct" || fail "serviceName is '$sn'"
rep=$(kubectl -n olympus get statefulset olympus-app -o jsonpath='{.spec.replicas}' 2>/dev/null)
[[ "$rep" == "3" ]] && pass "3 replicas declared" || fail "replicas is '$rep'"
ready=$(kubectl -n olympus get statefulset olympus-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[[ "$ready" == "3" ]] && pass "all 3 pods Ready" || fail "only '$ready' ready"
pods=$(kubectl -n olympus get pods -o jsonpath='{.items[*].metadata.name}')
grep -q "olympus-app-0" <<<"$pods" && grep -q "olympus-app-1" <<<"$pods" && grep -q "olympus-app-2" <<<"$pods" \
  && pass "predictable ordinal pod names (-0, -1, -2)" || fail "pod names don't look like a StatefulSet's"
dns=$(kubectl -n olympus run dns-test --image=busybox:1 -it --rm --restart=Never -- \
  nslookup olympus-app-0.olympus-svc.olympus.svc.cluster.local 2>&1 || true)
grep -qi "address" <<<"$dns" && pass "per-pod DNS resolves" || fail "DNS lookup for olympus-app-0 failed"
exit ${FAILED}
