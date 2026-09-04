#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q17:"
jp() { kubectl -n helios get deploy helios-batch -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "deployment exists" || { fail "helios-batch not found"; exit 1; }
tkey=$(jp '{.spec.template.spec.tolerations[0].key}')
teff=$(jp '{.spec.template.spec.tolerations[0].effect}')
tval=$(jp '{.spec.template.spec.tolerations[0].value}')
[[ "$tkey" == "dedicated" && "$tval" == "helios" && "$teff" == "NoSchedule" ]] && pass "toleration matches the taint" || fail "toleration is key=$tkey value=$tval effect=$teff"
ns=$(jp '{.spec.template.spec.nodeSelector.kubernetes\.io/hostname}')
[[ "$ns" == "lab-worker-1" ]] && pass "nodeSelector pins it to lab-worker-1" || fail "nodeSelector missing/wrong (got '$ns')"
actual_node=$(kubectl -n helios get pod -l app=helios-batch -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null)
[[ "$actual_node" == "lab-worker-1" ]] && pass "pod actually scheduled on lab-worker-1" || fail "pod landed on '$actual_node'"
running=$(kubectl -n helios get deploy helios-batch -o jsonpath='{.status.availableReplicas}')
[[ "$running" == "1" ]] && pass "pod Running" || fail "pod not available"
exit ${FAILED}
