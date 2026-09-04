#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q09:"

$SSH_CP "grep -qE '^namespace: *topaz' /course4/9/app/kustomization.yaml" && pass "kustomization sets namespace: topaz" || fail "kustomization.yaml has no 'namespace: topaz'"

rendered=$($SSH_CP "cat /course4/9/rendered.yaml 2>/dev/null" || true)
[[ -n "$rendered" ]] && pass "rendered.yaml exists" || fail "/course4/9/rendered.yaml missing"
n=$(echo "$rendered" | grep -c "namespace: topaz" || true)
[[ "$n" == "3" ]] && pass "rendered output places all 3 resources in topaz" || fail "rendered.yaml has 'namespace: topaz' $n times (expected 3 — render AFTER setting the namespace)"

count=$($SSH_CP "cat /course4/9/count 2>/dev/null" | tr -d '[:space:]') || true
[[ "$count" == "3" ]] && pass "count is 3" || fail "/course4/9/count is '$count' (expected 3)"

kubectl -n topaz get deploy topaz-web >/dev/null 2>&1 && pass "Deployment in topaz" || fail "Deployment topaz-web not in Namespace topaz"
kubectl -n topaz get svc topaz-web >/dev/null 2>&1 && pass "Service in topaz" || fail "Service topaz-web not in Namespace topaz"
kubectl -n topaz get cm topaz-config >/dev/null 2>&1 && pass "ConfigMap in topaz" || fail "ConfigMap topaz-config not in Namespace topaz"
ready=$(kubectl -n topaz get deploy topaz-web -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[[ "$ready" == "2" ]] && pass "2 Pods ready" || fail "only '$ready' Pods ready"

exit ${FAILED}
