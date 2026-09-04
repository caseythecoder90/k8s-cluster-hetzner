#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q01:"
out=$($SSH_CP "cat /course2/1/demo-pods 2>/dev/null" || true)
[[ -n "$out" ]] && pass "file non-empty" || { fail "/course2/1/demo-pods missing/empty"; exit 1; }
lines=$(echo "$out" | wc -l)
[[ "$lines" == "3" ]] && pass "exactly 3 names (decoy excluded)" || fail "expected 3 lines, got $lines"
sorted=$(echo "$out" | sort)
[[ "$out" == "$sorted" ]] && pass "sorted alphabetically" || fail "not sorted"
grep -q "myth-alpha-other" <<<"$out" && fail "decoy pod (wrong label) included" || pass "decoy correctly excluded"
exit ${FAILED}
