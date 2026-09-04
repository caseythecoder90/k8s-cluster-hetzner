#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q10:"
avail=$(kubectl -n hera get deploy hera-worker -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[[ "$avail" == "1" ]] && pass "pod fixed and available" || fail "pod not available (avail='$avail')"
rc=$($SSH_CP "cat /course2/10/root-cause.txt 2>/dev/null" || true)
[[ -n "$rc" ]] && pass "root-cause.txt non-empty" || fail "/course2/10/root-cause.txt missing"
exit ${FAILED}
