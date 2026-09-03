#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q15:"
jp() { kubectl -n chronos get deploy chronos-app -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "deployment exists" || { fail "chronos-app not found"; exit 1; }
secname=$(jp '{.spec.template.spec.volumes[?(@.secret.secretName=="chronos-creds")].name}')
[[ -n "$secname" ]] && pass "volume from chronos-creds present" || { fail "no secret volume"; exit 1; }
mode=$(jp "{.spec.template.spec.volumes[?(@.name==\"$secname\")].secret.defaultMode}")
[[ "$mode" == "256" ]] && pass "defaultMode is 0400 (256 decimal)" || fail "defaultMode is '$mode' (want 256 = 0400)"
mnt=$(jp "{.spec.template.spec.containers[0].volumeMounts[?(@.name==\"$secname\")].mountPath}")
[[ "$mnt" == "/etc/creds" ]] && pass "mounted at /etc/creds" || fail "mountPath is '$mnt'"
[[ "$(jp '{.status.availableReplicas}')" == "1" ]] && pass "pod running" || fail "pod not available"
exit ${FAILED}
