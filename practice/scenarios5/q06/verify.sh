#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q06:"

unchanged q06-base "$COURSE/6/base/*.yaml" && pass "base untouched" || fail "files in /course5/6/base were modified"
$SSH_CP "kubectl kustomize /course5/6/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/6/overlays/prod fails"; exit 1; }
$SSH_CP "grep -rqE '[\$]patch: *delete' /course5/6/overlays/" && pass "list element removed with \$patch: delete" || fail "no '\$patch: delete' in the overlay — omitting a container from a strategic merge patch does NOT delete it"
$SSH_CP "grep -rqE '^[[:space:]]*- op: ' /course5/6/overlays/" && fail "JSON 6902 ops found — this question asks for a strategic merge patch" || pass "strategic merge (no op: lines)"

jp() { kubectl -n tin get deploy solder -o jsonpath="$1" 2>/dev/null; }
names=$(jp '{.spec.template.spec.containers[*].name}' || true)
[[ -n "$names" ]] && pass "Deployment solder found in tin" || { fail "Deployment solder not found in Namespace tin — was the overlay applied?"; exit 1; }

n=$(echo "$names" | wc -w)
[[ "$n" == "3" ]] && pass "3 containers" || fail "container list is '$names' ($n entries, expected 3: web, cache, shipper)"
[[ "$names" != *"legacy"* ]] && pass "legacy removed" || fail "container 'legacy' is still there — a strategic merge is additive, deletion needs '\$patch: delete' next to the merge key"
[[ "$names" == *"shipper"* ]] && pass "shipper added" || fail "container 'shipper' was not added (a name not in the base is appended)"

[[ "$(jp '{.spec.template.spec.containers[?(@.name=="web")].image}')" == "nginx:1.27-alpine" ]] && pass "web image nginx:1.27-alpine" || fail "web image is '$(jp '{.spec.template.spec.containers[?(@.name=="web")].image}')' (expected nginx:1.27-alpine)"
[[ "$(jp '{.spec.template.spec.containers[?(@.name=="web")].ports[0].containerPort}')" == "80" ]] && pass "web still exposes containerPort 80" || fail "web lost its port — merging by name changes only the fields you name"
[[ "$(jp '{.spec.template.spec.containers[?(@.name=="web")].resources.requests.memory}')" == "12Mi" ]] && pass "web keeps its resource requests" || fail "web lost its requests — the container was replaced instead of merged"
[[ "$(jp '{.spec.template.spec.containers[?(@.name=="cache")].image}')" == "redis:7-alpine" ]] && pass "cache untouched" || fail "cache image is '$(jp '{.spec.template.spec.containers[?(@.name=="cache")].image}')' (expected redis:7-alpine, untouched)"
[[ "$(jp '{.spec.template.spec.containers[?(@.name=="shipper")].image}')" == "busybox:1" ]] && pass "shipper image busybox:1" || fail "shipper image is '$(jp '{.spec.template.spec.containers[?(@.name=="shipper")].image}')' (expected busybox:1)"

[[ "$(jp '{.status.readyReplicas}')" == "1" ]] && pass "Pod ready (3/3)" || fail "Pod not ready — kubectl -n tin get pods, does 'shipper' have a command that keeps it alive?"

exit ${FAILED}
