#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q06:"

f=$($SSH_CP "cat /course4/6/pearl-web.yaml 2>/dev/null" || true)
[[ -n "$f" ]] && pass "rendered file exists" || { fail "/course4/6/pearl-web.yaml missing"; exit 1; }
echo "$f" | grep -q "kind: Deployment" && echo "$f" | grep -q "kind: Service" && pass "file has a Deployment and a Service" || fail "file should contain the rendered Deployment and Service"
echo "$f" | grep -qE "replicas: 3$" && pass "file renders 3 replicas (--set beats the values file)" || fail "file does not contain 'replicas: 3'"
echo "$f" | grep -qE "nodePort: 30406$" && pass "file renders nodePort 30406 (from the values file)" || fail "file does not contain nodePort 30406 — was -f used?"

jp() { kubectl -n pearl get deploy pearl-web -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "Deployment pearl-web in pearl" || { fail "Deployment pearl-web not found in Namespace pearl"; exit 1; }
[[ "$(jp '{.spec.replicas}')" == "3" ]] && pass "3 replicas" || fail "replicas is '$(jp '{.spec.replicas}')'"
[[ "$(jp '{.status.readyReplicas}')" == "3" ]] && pass "3 Pods ready" || fail "only '$(jp '{.status.readyReplicas}')' Pods ready"
img=$(jp '{.spec.template.spec.containers[0].image}')
[[ "$img" == "nginx:1.27-alpine" ]] && pass "image nginx:1.27-alpine" || fail "image is '$img'"
nport=$(kubectl -n pearl get svc pearl-web -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
[[ "$nport" == "30406" ]] && pass "Service NodePort 30406" || fail "Service nodePort is '$nport'"

[[ -z "$(helm_field pearl pearl-web status)" ]] && pass "no Helm release pearl-web" || fail "a Helm release pearl-web exists — the task said kubectl, not helm install"
ann=$(jp '{.metadata.annotations.meta\.helm\.sh/release-name}')
[[ -z "$ann" ]] && pass "Deployment is not Helm-managed" || fail "Deployment carries Helm release annotations"

exit ${FAILED}
