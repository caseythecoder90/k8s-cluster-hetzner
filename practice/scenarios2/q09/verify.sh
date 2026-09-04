#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q09:"
$SSH_CP "test -s /course2/9/ares-report-deployment.yaml" && pass "deployment yaml saved" || fail "/course2/9/ares-report-deployment.yaml missing"
jp() { kubectl -n ares get deploy ares-report -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "deployment exists" || { fail "deployment not found"; exit 1; }
[[ "$(jp '{.spec.replicas}')" == "2" ]] && pass "2 replicas" || fail "replicas wrong"
vol=$(jp '{.spec.template.spec.volumes[?(@.configMap.name=="ares-report-config")].name}')
[[ -n "$vol" ]] && pass "volume from ares-report-config present" || fail "no configmap volume"
mnt=$(jp "{.spec.template.spec.containers[0].volumeMounts[?(@.name==\"$vol\")].mountPath}")
[[ "$mnt" == "/etc/report" ]] && pass "mounted at /etc/report" || fail "mountPath is '$mnt'"
[[ "$(jp '{.spec.template.spec.containers[0].resources.limits.cpu}')" == "100m" ]] && pass "cpu limit 100m" || fail "cpu limit wrong"
[[ "$(jp '{.spec.template.spec.containers[0].resources.limits.memory}')" == "64Mi" ]] && pass "memory limit 64Mi" || fail "memory limit wrong"
[[ "$(jp '{.status.availableReplicas}')" == "2" ]] && pass "2 pods available" || fail "pods not available"
kubectl -n ares get pod ares-report >/dev/null 2>&1 && fail "original Pod ares-report still exists" || pass "original pod deleted"
exit ${FAILED}
