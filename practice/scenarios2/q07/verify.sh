#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q07:"
n=$(kubectl -n poseidon get pod poseidon-web -o jsonpath='{.spec.containers[*].name}' 2>/dev/null | wc -w)
[[ "$n" == "2" ]] && pass "2 containers in the pod" || { fail "expected 2 containers, found $n"; exit 1; }
img=$(kubectl -n poseidon get pod poseidon-web -o jsonpath='{.spec.containers[?(@.name=="log-shipper")].image}')
[[ "$img" == "busybox:1" ]] && pass "log-shipper image busybox:1" || fail "log-shipper image is '$img'"
mnt=$(kubectl -n poseidon get pod poseidon-web -o jsonpath='{.spec.containers[?(@.name=="log-shipper")].volumeMounts[0].mountPath}')
[[ "$mnt" == "/var/log/app" ]] && pass "shares the log volume" || fail "log-shipper mountPath is '$mnt'"
ready=$(kubectl -n poseidon get pod poseidon-web -o jsonpath='{.status.containerStatuses[?(@.name=="log-shipper")].ready}')
[[ "$ready" == "true" ]] && pass "log-shipper Running" || fail "log-shipper not ready"
logs=$(kubectl -n poseidon logs poseidon-web -c log-shipper --tail=5 2>/dev/null)
grep -q "request" <<<"$logs" && pass "log-shipper is streaming real log content" || fail "log-shipper shows no app log content"
exit ${FAILED}
