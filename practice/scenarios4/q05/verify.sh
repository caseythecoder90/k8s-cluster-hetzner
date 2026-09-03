#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q05:"

[[ -z "$(helm_field onyx onyx-legacy status)" ]] && pass "onyx-legacy uninstalled" || fail "onyx-legacy still exists"

chart=$(helm_field onyx onyx-web chart)
[[ "$chart" == "nginx-1.2.0" ]] && pass "onyx-web upgraded to nginx-1.2.0" || fail "onyx-web chart is '$chart' (expected nginx-1.2.0)"
reps=$(kubectl -n onyx get deploy onyx-web -o jsonpath='{.spec.replicas}' 2>/dev/null)
[[ "$reps" == "2" ]] && pass "onyx-web kept its 2 replicas" || fail "onyx-web has '$reps' replicas — its values were lost in the upgrade (--reuse-values)"

stuck=$($SSH_CP "cat /course4/5/stuck 2>/dev/null" | tr -d '[:space:]') || true
[[ "$stuck" == "opal/report-generator" ]] && pass "stuck release identified: opal/report-generator" || fail "/course4/5/stuck is '$stuck' (expected opal/report-generator)"
[[ -z "$(helm_field opal report-generator status)" ]] && pass "stuck release uninstalled" || fail "report-generator in opal still exists (status: $(helm_field opal report-generator status))"

for r in jade-api jade-cache; do
  [[ "$(helm_field jade $r status)" == "deployed" ]] && pass "$r left alone" || fail "$r in jade was touched (status: '$(helm_field jade $r status)')"
done

count=$($SSH_CP "cat /course4/5/count 2>/dev/null" | tr -d '[:space:]') || true
[[ "$count" == "3" ]] && pass "count is 3" || fail "/course4/5/count is '$count' (expected 3: jade-api, jade-cache, onyx-web)"

exit ${FAILED}
