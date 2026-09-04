#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q03:"
jp() { kubectl -n zeus get cronjob zeus-backup -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "cronjob exists" || { fail "zeus-backup not found"; exit 1; }
[[ "$(jp '{.spec.schedule}')" == "*/5 * * * *" ]] && pass "schedule every 5 min" || fail "schedule is '$(jp '{.spec.schedule}')'"
[[ "$(jp '{.spec.concurrencyPolicy}')" == "Forbid" ]] && pass "concurrencyPolicy Forbid" || fail "concurrencyPolicy wrong"
[[ "$(jp '{.spec.successfulJobsHistoryLimit}')" == "2" ]] && pass "successfulJobsHistoryLimit 2" || fail "successful history limit wrong"
[[ "$(jp '{.spec.failedJobsHistoryLimit}')" == "1" ]] && pass "failedJobsHistoryLimit 1" || fail "failed history limit wrong"
img=$(jp '{.spec.jobTemplate.spec.template.spec.containers[0].image}')
[[ "$img" == "busybox:1" ]] && pass "image busybox:1" || fail "image is '$img'"
exit ${FAILED}
