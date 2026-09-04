#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q13:"
pv() { kubectl get pv dionysus-pv -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(pv '{.metadata.name}')" ]] && pass "PV exists" || { fail "dionysus-pv not found"; exit 1; }
[[ "$(pv '{.spec.hostPath.path}')" == "/mnt/data/dionysus" ]] && pass "hostPath correct" || fail "hostPath wrong"
[[ "$(pv '{.spec.capacity.storage}')" == "1Gi" ]] && pass "capacity 1Gi" || fail "capacity wrong"
[[ "$(pv '{.spec.storageClassName}')" == "manual" ]] && pass "storageClassName manual" || fail "storageClassName wrong"
pvc() { kubectl -n dionysus get pvc dionysus-pvc -o jsonpath="$1" 2>/dev/null; }
[[ "$(pvc '{.status.phase}')" == "Bound" ]] && pass "PVC is Bound" || fail "PVC phase is '$(pvc '{.status.phase}')'"
[[ "$(pvc '{.spec.volumeName}')" == "dionysus-pv" ]] && pass "PVC bound to the right PV" || fail "PVC bound to '$(pvc '{.spec.volumeName}')'"
exit ${FAILED}
