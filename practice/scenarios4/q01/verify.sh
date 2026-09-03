#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q01:"

$SSH_CP "helm repo list 2>/dev/null" | grep -q "^hk-charts" \
  && pass "repo hk-charts is registered" \
  || fail "helm repo list does not show hk-charts"

charts=$($SSH_CP "cat /course4/1/charts 2>/dev/null" || true)
ok=1
for c in api nginx redis; do echo "$charts" | grep -qw "$c" || ok=0; done
lines=$(echo "$charts" | grep -c . || true)
[[ $ok == 1 && $lines -eq 3 ]] \
  && pass "charts file lists api, nginx, redis" \
  || fail "/course4/1/charts should list exactly the 3 charts (api, nginx, redis) — got $lines line(s)"

vers=$($SSH_CP "cat /course4/1/api-versions 2>/dev/null" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | tr '\n' ' ' | sed 's/ $//') || true
[[ "$vers" == "2.2.0 2.1.0 2.0.0 1.0.0" ]] \
  && pass "api-versions: 2.2.0 2.1.0 2.0.0 1.0.0" \
  || fail "api-versions should read 2.2.0, 2.1.0, 2.0.0, 1.0.0 (chart versions, newest first) — found: '$vers'"

exit ${FAILED}
