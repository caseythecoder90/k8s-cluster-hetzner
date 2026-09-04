#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q05:"
SA=system:serviceaccount:apollo:apollo-reader
can_list=$(kubectl auth can-i list pods -n apollo --as="$SA" 2>/dev/null)
[[ "$can_list" == "yes" ]] && pass "can list pods" || fail "cannot list pods (expected yes, got '$can_list')"
can_get=$(kubectl auth can-i get pods -n apollo --as="$SA" 2>/dev/null)
[[ "$can_get" == "yes" ]] && pass "can get pods" || fail "cannot get pods"
can_delete=$(kubectl auth can-i delete pods -n apollo --as="$SA" 2>/dev/null)
[[ "$can_delete" == "no" ]] && pass "cannot delete pods (correctly restricted)" || fail "CAN delete pods — role too broad"
can_list_secrets=$(kubectl auth can-i list secrets -n apollo --as="$SA" 2>/dev/null)
[[ "$can_list_secrets" == "no" ]] && pass "cannot list secrets (correctly restricted)" || fail "CAN list secrets — role too broad"
exit ${FAILED}
