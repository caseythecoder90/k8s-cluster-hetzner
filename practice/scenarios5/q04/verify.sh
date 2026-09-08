#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q04:"

unchanged q04-base "$COURSE/4/base/*.yaml" && pass "base untouched" || fail "files in /course5/4/base were modified"
$SSH_CP "kubectl kustomize /course5/4/overlays/dev >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/4/overlays/dev fails"; exit 1; }
$SSH_CP "grep -qE '^\s*patches:' /course5/4/overlays/dev/kustomization.yaml" && pass "overlay uses patches:" || fail "no patches: field in the overlay kustomization.yaml"

jp() { kubectl -n nickel get deploy worker -o jsonpath="$1" 2>/dev/null; }
[[ "$(jp '{.spec.template.spec.containers[0].resources.limits.memory}')" == "256Mi" ]] && pass "memory limit 256Mi" || fail "memory limit is '$(jp '{.spec.template.spec.containers[0].resources.limits.memory}')'"
[[ "$(jp '{.spec.template.spec.containers[0].resources.requests.memory}')" == "8Mi" ]] && pass "memory request still 8Mi" || fail "the requests block was clobbered — a merge must not replace resources wholesale"
[[ "$(jp '{.metadata.annotations.maintainer}')" == "nickel-team" ]] && pass "annotation maintainer=nickel-team" || fail "annotation maintainer is '$(jp '{.metadata.annotations.maintainer}')'"
[[ "$(jp '{.status.readyReplicas}')" == "1" ]] && pass "Pod ready" || fail "Pod not ready"

exit ${FAILED}
