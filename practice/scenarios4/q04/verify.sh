#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q04:"

status=$(helm_field garnet garnet-api status)
chart=$(helm_field garnet garnet-api chart)
rev=$(helm_field garnet garnet-api revision)
[[ "$status" == "deployed" ]] && pass "release deployed" || fail "release status is '$status'"
[[ "$chart" == "api-2.0.0" ]] && pass "back on api-2.0.0" || fail "chart is '$chart' (expected api-2.0.0, the last working revision)"

hist=$($SSH_CP "helm -n garnet history garnet-api -o json 2>/dev/null" || true)
echo "$hist" | grep -q '"description":"Rollback to 2"' \
  && pass "history shows a rollback to revision 2" \
  || fail "no 'Rollback to 2' entry in helm history — was helm rollback used?"
[[ "$rev" == "4" ]] && pass "now at revision 4 (rollback creates a new revision)" || fail "release is at revision '$rev' (expected 4)"

jp() { kubectl -n garnet get deploy garnet-api -o jsonpath="$1" 2>/dev/null; }
[[ "$(jp '{.status.readyReplicas}')" == "2" ]] && pass "2 Pods ready" || fail "only '$(jp '{.status.readyReplicas}')' Pods ready"
img=$(jp '{.spec.template.spec.containers[0].image}')
[[ "$img" == "nginx:1-alpine" ]] && pass "image back to nginx:1-alpine" || fail "image is '$img'"

f1=$($SSH_CP "cat /course4/4/revision 2>/dev/null" | tr -d '[:space:]') || true
f2=$($SSH_CP "cat /course4/4/chart-version 2>/dev/null" | tr -d '[:space:]') || true
[[ "$f1" == "4" ]] && pass "revision file says 4" || fail "/course4/4/revision is '$f1' (expected 4 — the rollback itself is a new revision, not 2)"
[[ "$f2" == "2.0.0" ]] && pass "chart-version file says 2.0.0" || fail "/course4/4/chart-version is '$f2' (expected 2.0.0)"

exit ${FAILED}
