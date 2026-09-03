#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q06:"
img=$(kubectl -n artemis get deploy artemis-api -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
[[ "$img" == "nginx:1.30-alpine" ]] && pass "image restored to working tag" || fail "image is '$img'"
avail=$(kubectl -n artemis get deploy artemis-api -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[[ "$avail" == "2" ]] && pass "2 pods available" || fail "only '$avail' pods available"
rev=$(kubectl -n artemis get deploy artemis-api -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}')
[[ "${rev:-0}" -ge 3 ]] && pass "rollback recorded as a new revision ($rev)" || fail "revision is $rev — did undo actually run?"
exit ${FAILED}
