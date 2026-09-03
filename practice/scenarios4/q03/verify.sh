#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q03:"

status=$(helm_field coral coral-web status)
chart=$(helm_field coral coral-web chart)
rev=$(helm_field coral coral-web revision)
[[ "$status" == "deployed" ]] && pass "release deployed" || fail "release status is '$status'"
[[ "$chart" == "nginx-1.2.0" ]] && pass "upgraded to nginx-1.2.0" || fail "chart is '$chart' (expected nginx-1.2.0, the newest)"

jp() { kubectl -n coral get deploy coral-web -o jsonpath="$1" 2>/dev/null; }
img=$(jp '{.spec.template.spec.containers[0].image}')
[[ "$img" == "nginx:1.27-alpine" ]] && pass "image nginx:1.27-alpine" || fail "image is '$img' (expected nginx:1.27-alpine)"
[[ "$(jp '{.spec.replicas}')" == "4" ]] && pass "still 4 replicas" || fail "replicas is '$(jp '{.spec.replicas}')' — the original value (4) was lost in the upgrade"

stype=$(kubectl -n coral get svc coral-web -o jsonpath='{.spec.type}' 2>/dev/null)
nport=$(kubectl -n coral get svc coral-web -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
[[ "$stype" == "NodePort" && "$nport" == "30403" ]] && pass "still NodePort 30403" || fail "Service is type='$stype' nodePort='$nport' — the original values were lost in the upgrade"

[[ "$(jp '{.status.readyReplicas}')" == "4" ]] && pass "4 Pods ready" || fail "only '$(jp '{.status.readyReplicas}')' Pods ready"

file=$($SSH_CP "cat /course4/3/revision 2>/dev/null" | tr -d '[:space:]') || true
[[ -n "$rev" && "$file" == "$rev" ]] && pass "revision file matches ($rev)" || fail "/course4/3/revision is '$file', the release is at revision '$rev'"
[[ "$rev" == "2" ]] && pass "done in a single upgrade (revision 2)" || fail "release is at revision $rev — the task wanted one upgrade (revision 2)"

exit ${FAILED}
