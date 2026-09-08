#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q05:"

unchanged q05-base "$COURSE/5/base/*.yaml" && pass "base untouched" || fail "files in /course5/5/base were modified"
$SSH_CP "kubectl kustomize /course5/5/overlays/dev >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/5/overlays/dev fails"; exit 1; }
$SSH_CP "grep -rqE 'null' /course5/5/overlays/dev/" && pass "overlay deletes with null" || fail "no 'null' anywhere in the overlay — strategic merge deletes a key with 'key: null'"
$SSH_CP "grep -rqE '^\s*- op: ' /course5/5/overlays/dev/" && fail "JSON 6902 ops found — this question asks for a strategic merge patch" || pass "strategic merge (no op: lines)"

jp() { kubectl -n zinc get deploy ledger -o jsonpath="$1" 2>/dev/null; }
[[ -z "$(jp '{.metadata.annotations.zinc\.io/deprecated}')" ]] && pass "zinc.io/deprecated removed" || fail "annotation zinc.io/deprecated is still there"
[[ "$(jp '{.metadata.annotations.zinc\.io/team}')" == "zinc" ]] && pass "zinc.io/team kept" || fail "annotation zinc.io/team was removed too"
[[ -z "$(jp '{.spec.template.spec.nodeSelector}')" ]] && pass "nodeSelector removed" || fail "nodeSelector is still '$(jp '{.spec.template.spec.nodeSelector}')'"
[[ "$(jp '{.status.readyReplicas}')" == "1" ]] && pass "Pod running" || fail "Pod still not ready — is the nodeSelector really gone?"

exit ${FAILED}
