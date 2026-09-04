#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q08:"
rp='{.spec.template.spec.containers[0].readinessProbe'
jp() { kubectl -n hades get deploy hades-cache -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp "$rp}")" ]] && pass "readinessProbe present" || { fail "no readinessProbe"; exit 1; }
cmd=$(jp "$rp.exec.command}")
[[ "$cmd" == *"/tmp/ready"* ]] && pass "exec probe checks /tmp/ready" || fail "exec command doesn't reference /tmp/ready"
[[ "$(jp "$rp.periodSeconds}")" == "5" ]] && pass "periodSeconds 5" || fail "periodSeconds wrong"
[[ "$(jp "$rp.failureThreshold}")" == "3" ]] && pass "failureThreshold 3" || fail "failureThreshold wrong"
sleep 12
ready=$(kubectl -n hades get pod -l app=hades-cache -o jsonpath='{.items[0].status.containerStatuses[0].ready}')
[[ "$ready" == "true" ]] && pass "pod became Ready after warm-up" || fail "pod not Ready after waiting"
eps=$(kubectl -n hades get endpointslices -l kubernetes.io/service-name=hades-cache-svc -o jsonpath='{.items[*].endpoints[*].addresses[*]}')
[[ -n "$eps" ]] && pass "service has an endpoint" || fail "service has no endpoints"
exit ${FAILED}
