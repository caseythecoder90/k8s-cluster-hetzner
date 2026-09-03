#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q08:"

chartyaml=$($SSH_CP "cat /course4/8/redis/Chart.yaml 2>/dev/null" || true)
[[ -n "$chartyaml" ]] && pass "/course4/8/redis/Chart.yaml exists" || { fail "/course4/8/redis/Chart.yaml missing (helm pull --untar?)"; exit 1; }
echo "$chartyaml" | grep -q "^version: 0.6.0" && pass "chart version 0.6.0" || fail "extracted chart is not version 0.6.0"

$SSH_CP "grep -qE '^replicaCount: *2$' /course4/8/redis/values.yaml" && pass "values.yaml default replicaCount: 2" || fail "values.yaml does not have replicaCount: 2"

status=$(helm_field ruby ruby-cache status)
chart=$(helm_field ruby ruby-cache chart)
[[ "$status" == "deployed" ]] && pass "release ruby-cache deployed" || fail "release ruby-cache status is '$status'"
[[ "$chart" == "redis-0.6.0" ]] && pass "chart redis-0.6.0" || fail "chart is '$chart'"

jp() { kubectl -n ruby get deploy ruby-cache -o jsonpath="$1" 2>/dev/null; }
[[ "$(jp '{.spec.replicas}')" == "2" ]] && pass "2 replicas" || fail "replicas is '$(jp '{.spec.replicas}')'"
[[ "$(jp '{.status.readyReplicas}')" == "2" ]] && pass "2 Pods ready" || fail "only '$(jp '{.status.readyReplicas}')' Pods ready"

uv=$($SSH_CP "helm -n ruby get values ruby-cache -o json 2>/dev/null" | tr -d '[:space:]') || true
[[ "$uv" == "null" || "$uv" == "{}" ]] && pass "no values passed on the command line" || fail "helm get values shows user-supplied values ($uv) — the chart default was supposed to do it"

exit ${FAILED}
