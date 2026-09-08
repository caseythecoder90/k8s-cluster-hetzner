#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q10:"

unchanged q10-base "$COURSE/10/base/*.yaml" && pass "base untouched" || fail "files in /course5/10/base were modified"
$SSH_CP "kubectl kustomize /course5/10/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/10/overlays/prod fails"; exit 1; }
$SSH_CP "grep -rqE '^[[:space:]]*- op: *(add|replace|remove)' /course5/10/overlays/" && pass "JSON 6902 ops found" || fail "no JSON 6902 operations (- op: ...) in /course5/10/overlays"
$SSH_CP "grep -rqE 'apiVersion: *apps/v1' /course5/10/overlays/" && fail "a strategic merge patch (apiVersion: apps/v1) is present — this question is JSON 6902 only" || pass "no strategic merge patch"

jp() { kubectl -n pewter get deploy foundry -o jsonpath="$1" 2>/dev/null; }
names=$(jp '{.spec.template.spec.containers[*].name}' || true)
[[ -n "$names" ]] && pass "Deployment foundry found in pewter" || { fail "Deployment foundry not found in Namespace pewter — was the overlay applied?"; exit 1; }

[[ "$(echo "$names" | wc -w)" == "4" ]] && pass "4 containers" || fail "container list is '$names' (expected 4)"
[[ "$names" == "proxy app log metrics" ]] && pass "order is proxy, app, log, metrics" || fail "container ORDER is '$names', expected 'proxy app log metrics' — /- appends, /0 INSERTS at the front and shifts everything after it"

[[ "$(jp '{.spec.template.spec.containers[0].image}')" == "busybox:1" ]] && pass "containers[0] proxy image busybox:1" || fail "containers[0].image is '$(jp '{.spec.template.spec.containers[0].image}')' (expected busybox:1)"
[[ "$(jp '{.spec.template.spec.containers[1].image}')" == "nginx:1.27-alpine" ]] && pass "containers[1] app image nginx:1.27-alpine" || fail "containers[1].image is '$(jp '{.spec.template.spec.containers[1].image}')' (expected nginx:1.27-alpine — remember the insert shifted app from index 0 to index 1)"
[[ "$(jp '{.spec.template.spec.containers[1].ports[0].containerPort}')" == "80" ]] && pass "app kept its containerPort 80" || fail "app has no containerPort 80 — 'replace /containers/1' wipes the WHOLE element; to change one field the path must point INTO it (/containers/1/image)"
[[ "$(jp '{.spec.template.spec.containers[1].resources.requests.memory}')" == "12Mi" ]] && pass "app kept its resource requests" || fail "app's requests.memory is '$(jp '{.spec.template.spec.containers[1].resources.requests.memory}')' (expected 12Mi — the whole container element was replaced)"
[[ "$(jp '{.spec.template.spec.containers[2].image}')" == "busybox:1" ]] && pass "containers[2] log untouched" || fail "containers[2].image is '$(jp '{.spec.template.spec.containers[2].image}')' (expected busybox:1)"
[[ "$(jp '{.spec.template.spec.containers[2].resources.requests.memory}')" == "8Mi" ]] && pass "log untouched" || fail "the log container was modified — it should be left exactly as the base has it"
[[ "$(jp '{.spec.template.spec.containers[3].image}')" == "busybox:1" ]] && pass "containers[3] metrics image busybox:1" || fail "containers[3].image is '$(jp '{.spec.template.spec.containers[3].image}')' (expected busybox:1)"

[[ "$(jp '{.status.readyReplicas}')" == "1" ]] && pass "Pod ready (4/4)" || fail "Pod not ready — kubectl -n pewter get pods; do proxy and metrics have a command that keeps them alive?"

exit ${FAILED}
