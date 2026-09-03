#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q12:"

unchanged q12-base "/course4/12/base/*.yaml" && pass "base untouched" || fail "files in /course4/12/base were modified"
$SSH_CP "grep -rqE '^\s*- op: *(replace|add|remove)' /course4/12/overlays/dev/" && pass "dev overlay contains JSON 6902 ops" || fail "no JSON 6902 operations (op: ...) found in /course4/12/overlays/dev"
$SSH_CP "kubectl kustomize /course4/12/overlays/dev >/dev/null 2>&1" && pass "overlay renders" || fail "kubectl kustomize /course4/12/overlays/dev fails"

jp() { kubectl -n jasper get deploy jasper-worker -o jsonpath="$1" 2>/dev/null; }
mode=$(jp '{.spec.template.spec.containers[0].env[?(@.name=="MODE")].value}')
debug=$(jp '{.spec.template.spec.containers[0].env[?(@.name=="DEBUG")].value}')
nenv=$(jp '{.spec.template.spec.containers[0].env[*].name}' | wc -w)
[[ "$mode" == "stream" ]] && pass "MODE=stream" || fail "MODE is '$mode' (expected stream)"
[[ "$debug" == "true" ]] && pass "DEBUG=true" || fail "DEBUG is '$debug' (expected true)"
[[ "$nenv" == "2" ]] && pass "env list has exactly 2 entries" || fail "env list has $nenv entries (expected 2: MODE, DEBUG)"
[[ -z "$(jp '{.metadata.annotations.jasper\.io/legacy-owner}')" ]] && pass "legacy-owner annotation removed" || fail "annotation jasper.io/legacy-owner still present (escape the slash as ~1)"
[[ "$(jp '{.metadata.annotations.jasper\.io/team}')" == "jasper" ]] && pass "team annotation kept" || fail "annotation jasper.io/team is gone"
[[ "$(jp '{.status.readyReplicas}')" == "1" ]] && pass "Pod running" || fail "Pod not ready"

exit ${FAILED}
