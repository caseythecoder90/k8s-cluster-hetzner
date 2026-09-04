#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q02:"
jp() { kubectl -n athena get deploy athena-web -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "deployment exists" || { fail "athena-web not found"; exit 1; }
[[ "$(jp '{.spec.replicas}')" == "2" ]] && pass "2 replicas" || fail "replicas wrong"
[[ "$(jp '{.spec.template.spec.containers[0].name}')" == "web" ]] && pass "container name web" || fail "container name wrong"
[[ "$(jp '{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}')" == "athena-config" ]] && pass "envFrom references athena-config" || fail "envFrom missing/wrong"
[[ "$(jp '{.spec.template.spec.containers[0].env[?(@.name=="CACHE_TTL")].value}')" == "60" ]] && pass "CACHE_TTL=60 set" || fail "CACHE_TTL missing"
[[ "$(jp '{.status.availableReplicas}')" == "2" ]] && pass "2 pods available" || fail "pods not available"
exit ${FAILED}
