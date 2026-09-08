#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q07:"

unchanged q07-base "$COURSE/7/base/*.yaml" && pass "base untouched" || fail "files in /course5/7/base were modified"
$SSH_CP "kubectl kustomize /course5/7/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/7/overlays/prod fails"; exit 1; }
$SSH_CP "grep -qE '^[[:space:]]*patches:' /course5/7/overlays/prod/kustomization.yaml" && pass "overlay uses patches:" || fail "no patches: field in /course5/7/overlays/prod/kustomization.yaml"

jp() { kubectl -n iron get deploy refinery -o jsonpath="$1" 2>/dev/null; }
args=$(jp '{.spec.template.spec.containers[0].args[*]}' || true)
[[ -n "$args" ]] && pass "Deployment refinery found in iron" || { fail "Deployment refinery not found in iron, or its args list is empty — was the overlay applied?"; exit 1; }

n=$(echo "$args" | wc -w)
[[ "$n" == "4" ]] && pass "args has exactly 4 entries" || fail "args is [$args] — $n entries, expected 4. A scalar list has no merge key: a strategic merge REPLACES args wholesale, so the patch must list every entry you want to keep"
[[ "$(jp '{.spec.template.spec.containers[0].args[0]}')" == "--mode=stream" ]] && pass "args[0] --mode=stream" || fail "args[0] is '$(jp '{.spec.template.spec.containers[0].args[0]}')' (expected --mode=stream)"
[[ "$(jp '{.spec.template.spec.containers[0].args[1]}')" == "--level=debug" ]] && pass "args[1] --level=debug" || fail "args[1] is '$(jp '{.spec.template.spec.containers[0].args[1]}')' (expected --level=debug)"
[[ "$(jp '{.spec.template.spec.containers[0].args[2]}')" == "--retries=3" ]] && pass "args[2] --retries=3 survived" || fail "args[2] is '$(jp '{.spec.template.spec.containers[0].args[2]}')' (expected --retries=3 — an unchanged entry still has to be written out)"
[[ "$(jp '{.spec.template.spec.containers[0].args[3]}')" == "--timeout=60s" ]] && pass "args[3] --timeout=60s" || fail "args[3] is '$(jp '{.spec.template.spec.containers[0].args[3]}')' (expected --timeout=60s)"

[[ "$(jp '{.spec.template.spec.containers[0].command[0]}')" == "sh" ]] && pass "command[0] still sh" || fail "command[0] is '$(jp '{.spec.template.spec.containers[0].command[0]}')' — the command list must not change"
[[ "$(jp '{.spec.template.spec.containers[0].command[3]}')" == "--" ]] && pass "command list intact" || fail "the command list was truncated or replaced (command[3] is '$(jp '{.spec.template.spec.containers[0].command[3]}')', expected --)"
[[ "$(jp '{.spec.template.spec.containers[0].image}')" == "busybox:1" ]] && pass "image untouched" || fail "image is '$(jp '{.spec.template.spec.containers[0].image}')' (expected busybox:1)"

[[ "$(jp '{.status.readyReplicas}')" == "1" ]] && pass "Pod running" || fail "Pod not ready — kubectl -n iron get pods"

exit ${FAILED}
