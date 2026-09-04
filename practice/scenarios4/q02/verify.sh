#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q02:"

kubectl get ns beryl >/dev/null 2>&1 && pass "Namespace beryl exists" || { fail "Namespace beryl does not exist"; exit 1; }

status=$(helm_field beryl beryl-api status)
chart=$(helm_field beryl beryl-api chart)
[[ "$status" == "deployed" ]] && pass "release beryl-api is deployed" || fail "release beryl-api status is '$status' (expected deployed)"
[[ "$chart" == "api-2.1.0" ]] && pass "chart version 2.1.0" || fail "chart is '$chart' (expected api-2.1.0 — did you pass --version?)"

jp() { kubectl -n beryl get deploy beryl-api -o jsonpath="$1" 2>/dev/null; }
[[ "$(jp '{.spec.replicas}')" == "3" ]] && pass "3 replicas" || fail "replicas is '$(jp '{.spec.replicas}')' (expected 3)"
[[ "$(jp '{.status.readyReplicas}')" == "3" ]] && pass "3 Pods ready" || fail "only '$(jp '{.status.readyReplicas}')' Pods ready"

env=$(jp '{.spec.template.spec.containers[0].env[?(@.name=="LOG_LEVEL")].value}')
[[ "$env" == "debug" ]] && pass "env LOG_LEVEL=debug" || fail "container env LOG_LEVEL is '$env' (expected debug)"

stype=$(kubectl -n beryl get svc beryl-api -o jsonpath='{.spec.type}' 2>/dev/null)
nport=$(kubectl -n beryl get svc beryl-api -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
[[ "$stype" == "NodePort" && "$nport" == "30402" ]] && pass "Service NodePort 30402" || fail "Service is type='$stype' nodePort='$nport' (expected NodePort/30402)"

# "via Helm values" — the values must be recorded in the release, not patched in
# with kubectl afterwards. Checked one field at a time so a failure says which.
rc=$(helm_value beryl beryl-api replicaCount)
[[ "$rc" == "3" ]] && pass "helm get values records replicaCount=3" || fail "helm get values shows replicaCount='$rc' (expected 3) — set it via Helm, not kubectl"
np=$(helm_value beryl beryl-api service.nodePort)
[[ "$np" == "30402" ]] && pass "helm get values records service.nodePort=30402" || fail "helm get values shows service.nodePort='$np' (expected 30402) — set it via Helm, not kubectl"

$SSH_CP "curl -s -m 5 http://10.10.1.10:30402" | grep -q "Welcome to nginx" && pass "answers on :30402" || fail "nothing answers on 10.10.1.10:30402"

exit ${FAILED}
