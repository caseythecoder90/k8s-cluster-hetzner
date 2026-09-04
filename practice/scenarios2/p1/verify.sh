#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "p1:"
status=$($SSH_CP "helm status iris-web -n iris -o json 2>/dev/null" | grep -o '"status":"[a-z]*"' | head -1)
[[ "$status" == '"status":"deployed"' ]] && pass "release deployed" || { fail "helm status not 'deployed' (got $status)"; exit 1; }
rep=$(kubectl -n iris get deploy iris-web -o jsonpath='{.spec.replicas}' 2>/dev/null)
[[ "$rep" == "2" ]] && pass "replicaCount 2" || fail "replicas is '$rep'"
img=$(kubectl -n iris get deploy iris-web -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[[ "$img" == "nginx:1.27-alpine" ]] && pass "image tag upgraded" || fail "image is '$img'"
revs=$($SSH_CP "helm history iris-web -n iris --max=10 2>/dev/null" | grep -c "^[0-9]" || true)
[[ "$revs" -ge 2 ]] && pass "history shows $revs revisions" || fail "history shows only $revs revision(s)"
exit ${FAILED}
