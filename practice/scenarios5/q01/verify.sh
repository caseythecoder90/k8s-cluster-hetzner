#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q01:"

unchanged q01-base "$COURSE/1/base/*.yaml" && pass "base untouched" || fail "files in /course5/1/base were modified"
$SSH_CP "kubectl kustomize /course5/1/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/1/overlays/prod fails"; exit 1; }

r=$($SSH_CP "cat /course5/1/rendered.yaml 2>/dev/null" || true)
[[ -n "$r" ]] && pass "/course5/1/rendered.yaml exists" || fail "/course5/1/rendered.yaml missing (kubectl kustomize <dir> > file)"
echo "$r" | grep -q "name: pr-web-v2" && pass "rendered file carries the prefixed+suffixed name" || fail "rendered file has no 'pr-web-v2'"

jp() { kubectl -n copper get "$1" pr-web-v2 -o jsonpath="$2" 2>/dev/null; }
[[ -n "$(jp deploy '{.metadata.name}')" ]] && pass "Deployment pr-web-v2 in copper" || { fail "Deployment pr-web-v2 not found in Namespace copper"; exit 1; }
[[ -n "$(jp svc '{.metadata.name}')" ]] && pass "Service pr-web-v2 in copper" || fail "Service pr-web-v2 not found in copper"
[[ "$(jp deploy '{.metadata.annotations.owner}')" == "copper" ]] && pass "Deployment annotation owner=copper" || fail "Deployment annotation owner is '$(jp deploy '{.metadata.annotations.owner}')'"
[[ "$(jp svc '{.metadata.annotations.owner}')" == "copper" ]] && pass "Service annotation owner=copper" || fail "Service is missing the owner annotation — commonAnnotations covers every resource"
[[ "$(jp deploy '{.status.readyReplicas}')" == "1" ]] && pass "Pod ready" || fail "Pod not ready"

exit ${FAILED}
