#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q08:"

unchanged q08-base "$COURSE/8/base/*.yaml" && pass "base untouched" || fail "files in /course5/8/base were modified"
$SSH_CP "kubectl kustomize /course5/8/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/8/overlays/prod fails — 'replace' and 'remove' error out when the path is not in the base"; exit 1; }
$SSH_CP "grep -rqE '^[[:space:]]*- op: *(add|replace|remove)' /course5/8/overlays/" && pass "JSON 6902 ops found" || fail "no JSON 6902 operations (- op: ...) in /course5/8/overlays"
$SSH_CP "grep -rqE 'apiVersion: *apps/v1' /course5/8/overlays/" && fail "a strategic merge patch (apiVersion: apps/v1) is present — this question is JSON 6902 only" || pass "no strategic merge patch"

jp() { kubectl -n chrome get deploy plating -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "Deployment plating found in chrome" || { fail "Deployment plating not found in Namespace chrome — was the overlay applied?"; exit 1; }

[[ "$(jp '{.spec.template.spec.containers[0].env[?(@.name=="LOG_LEVEL")].value}')" == "debug" ]] && pass "LOG_LEVEL=debug" || fail "LOG_LEVEL is '$(jp '{.spec.template.spec.containers[0].env[?(@.name=="LOG_LEVEL")].value}')' (expected debug — the path /env/0/value already exists, so replace or add both work)"
[[ "$(jp '{.spec.template.spec.containers[0].env[*].name}' | wc -w)" == "1" ]] && pass "env list still has exactly 1 entry" || fail "env list is '$(jp '{.spec.template.spec.containers[0].env[*].name}')' — LOG_LEVEL was to be changed in place, not appended"
[[ "$(jp '{.spec.template.spec.containers[0].imagePullPolicy}')" == "Always" ]] && pass "imagePullPolicy Always" || fail "imagePullPolicy is '$(jp '{.spec.template.spec.containers[0].imagePullPolicy}')' — the base has no imagePullPolicy, so this path had to be CREATED (add), not replaced. Note IfNotPresent is what the API server defaults a tagged image to, so seeing it means the patch never landed"
[[ -z "$(jp '{.metadata.labels.retired}')" ]] && pass "label retired removed" || fail "label retired is still '$(jp '{.metadata.labels.retired}')' — remove takes a path and no value:"
[[ "$(jp '{.metadata.labels.app}')" == "plating" ]] && pass "label app=plating kept" || fail "label app is '$(jp '{.metadata.labels.app}')' — the whole labels map was removed instead of the one key"

[[ "$(jp '{.spec.template.spec.containers[0].image}')" == "nginx:1-alpine" ]] && pass "image untouched" || fail "image is '$(jp '{.spec.template.spec.containers[0].image}')' (expected nginx:1-alpine)"
[[ "$(jp '{.spec.template.spec.containers[0].ports[0].containerPort}')" == "80" ]] && pass "containerPort 80 untouched" || fail "the container's port is gone — an op pointed at the container itself instead of into it"
[[ "$(jp '{.spec.template.spec.containers[0].resources.requests.memory}')" == "12Mi" ]] && pass "resource requests untouched" || fail "requests.memory is '$(jp '{.spec.template.spec.containers[0].resources.requests.memory}')' (expected 12Mi)"

[[ "$(jp '{.status.readyReplicas}')" == "1" ]] && pass "Pod running" || fail "Pod not ready — kubectl -n chrome get pods"

exit ${FAILED}
