#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q02:"

unchanged q02-base "$COURSE/2/base/*.yaml" && pass "base untouched" || fail "files in /course5/2/base were modified"
$SSH_CP "kubectl kustomize /course5/2/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/2/overlays/prod fails"; exit 1; }
$SSH_CP "grep -qE '^\s*(patches|patchesStrategicMerge|patchesJson6902):' /course5/2/overlays/prod/kustomization.yaml" \
  && fail "a patch was used — this question is transformers only (replicas:, images:)" \
  || pass "no patches used"

jp() { kubectl -n silver get deploy "$1" -o jsonpath="$2" 2>/dev/null; }
[[ "$(jp sv-api '{.spec.replicas}')" == "3" ]] && pass "sv-api 3 replicas" || fail "sv-api replicas is '$(jp sv-api '{.spec.replicas}')' (replicas[].name uses the BASE name 'api')"
[[ "$(jp sv-cache '{.spec.replicas}')" == "2" ]] && pass "sv-cache 2 replicas" || fail "sv-cache replicas is '$(jp sv-cache '{.spec.replicas}')'"
[[ "$(jp sv-api '{.spec.template.spec.containers[0].image}')" == "nginx:1.27-alpine" ]] && pass "api image nginx:1.27-alpine" || fail "api image is '$(jp sv-api '{.spec.template.spec.containers[0].image}')' (images[].name is the IMAGE 'nginx', not the container 'main')"
[[ "$(jp sv-cache '{.spec.template.spec.containers[0].image}')" == "redis:7.2-alpine" ]] && pass "cache image redis:7.2-alpine" || fail "cache image is '$(jp sv-cache '{.spec.template.spec.containers[0].image}')' (changing the repository needs newName as well as newTag)"
[[ "$(jp sv-api '{.status.readyReplicas}')" == "3" ]] && pass "3 api Pods ready" || fail "only '$(jp sv-api '{.status.readyReplicas}')' api Pods ready"
[[ "$(jp sv-cache '{.status.readyReplicas}')" == "2" ]] && pass "2 cache Pods ready" || fail "only '$(jp sv-cache '{.status.readyReplicas}')' cache Pods ready — redis-oss does not exist, so the image must be repointed"

exit ${FAILED}
