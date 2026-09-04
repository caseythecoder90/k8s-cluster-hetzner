#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q16:"
jp() { kubectl -n atlas get deploy atlas-web -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "deployment exists" || { fail "atlas-web not found"; exit 1; }
icname=$(jp '{.spec.template.spec.initContainers[0].name}')
[[ "$icname" == "wait-for-db" ]] && pass "initContainer named wait-for-db" || fail "initContainer name is '$icname'"
icimg=$(jp '{.spec.template.spec.initContainers[0].image}')
[[ "$icimg" == "busybox:1" ]] && pass "initContainer image busybox:1" || fail "initContainer image is '$icimg'"
cmd=$(jp '{.spec.template.spec.initContainers[0].command}{.spec.template.spec.initContainers[0].args}')
[[ "$cmd" == *"atlas-db-svc"* && "$cmd" == *"5432"* ]] && pass "checks atlas-db-svc:5432" || fail "init command doesn't reference atlas-db-svc:5432"
[[ "$(jp '{.status.availableReplicas}')" == "1" ]] && pass "pod running (init succeeded, app started)" || fail "pod not available"
exit ${FAILED}
