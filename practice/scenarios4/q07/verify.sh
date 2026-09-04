#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q07:"

vals=$($SSH_CP "cat /course4/7/values.yaml 2>/dev/null" || true)
echo "$vals" | grep -qE "tag: *['\"]?1\.27-alpine['\"]?$" && pass "values.yaml has the fixed tag" || fail "values.yaml does not contain tag: 1.27-alpine"
echo "$vals" | grep -q "replicaCount: 2" && echo "$vals" | grep -q "nodePort: 30407" && pass "rest of values.yaml intact" || fail "values.yaml lost replicaCount: 2 or nodePort: 30407"

status=$(helm_field quartz quartz-api status)
rev=$(helm_field quartz quartz-api revision)
[[ "$status" == "deployed" ]] && pass "release deployed" || fail "release status is '$status'"
[[ "$rev" -ge 2 ]] 2>/dev/null && pass "release was upgraded (revision $rev)" || fail "release is still at revision '$rev' — the fix must go through helm upgrade"

jp() { kubectl -n quartz get deploy quartz-api -o jsonpath="$1" 2>/dev/null; }
img=$(jp '{.spec.template.spec.containers[0].image}')
[[ "$img" == "nginx:1.27-alpine" ]] && pass "image nginx:1.27-alpine" || fail "image is '$img'"
[[ "$(jp '{.spec.replicas}')" == "2" ]] && pass "still 2 replicas" || fail "replicas is '$(jp '{.spec.replicas}')' — was the values file passed to the upgrade?"
[[ "$(jp '{.status.readyReplicas}')" == "2" ]] && pass "2 Pods ready" || fail "only '$(jp '{.status.readyReplicas}')' Pods ready"
nport=$(kubectl -n quartz get svc quartz-api -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
[[ "$nport" == "30407" ]] && pass "still NodePort 30407" || fail "Service nodePort is '$nport'"

uv=$($SSH_CP "helm -n quartz get values quartz-api -o json 2>/dev/null" || true)
echo "$uv" | grep -q '"tag":"1.27-alpine"' && pass "helm get values reflects the fixed file" || fail "helm get values does not show tag 1.27-alpine"

exit ${FAILED}
