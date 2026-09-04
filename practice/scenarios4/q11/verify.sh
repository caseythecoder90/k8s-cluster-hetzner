#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q11:"

unchanged q11-base "/course4/11/base/*.yaml" && pass "base untouched" || fail "files in /course4/11/base were modified"

patch=$($SSH_CP "cat /course4/11/overlays/prod/patch-resources.yaml 2>/dev/null" || true)
[[ -n "$patch" ]] && pass "patch-resources.yaml exists" || { fail "/course4/11/overlays/prod/patch-resources.yaml missing"; exit 1; }
echo "$patch" | grep -q "kind: Deployment" && echo "$patch" | grep -q "name: agate-api" && ! echo "$patch" | grep -qE "^\s*- op:" \
  && pass "it is a strategic merge patch (a Deployment fragment)" \
  || fail "patch-resources.yaml should be a Deployment fragment (strategic merge), not a JSON 6902 op list"
$SSH_CP "grep -q 'patch-resources.yaml' /course4/11/overlays/prod/kustomization.yaml" && pass "kustomization references the patch" || fail "kustomization.yaml does not reference patch-resources.yaml"
$SSH_CP "kubectl kustomize /course4/11/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || fail "kubectl kustomize /course4/11/overlays/prod fails"

jp() { kubectl -n agate get deploy agate-api -o jsonpath="$1" 2>/dev/null; }
c='{.spec.template.spec.containers[?(@.name=="api")]'
[[ "$(jp "$c.resources.requests.cpu}")" == "50m" && "$(jp "$c.resources.requests.memory}")" == "32Mi" ]] && pass "requests cpu=50m memory=32Mi" || fail "requests are cpu='$(jp "$c.resources.requests.cpu}")' memory='$(jp "$c.resources.requests.memory}")'"
[[ "$(jp "$c.resources.limits.memory}")" == "64Mi" ]] && pass "limits memory=64Mi" || fail "limits.memory is '$(jp "$c.resources.limits.memory}")'"
[[ "$(jp "$c.readinessProbe.httpGet.path}")" == "/" && "$(jp "$c.readinessProbe.httpGet.port}")" == "80" ]] && pass "readinessProbe httpGet / :80" || fail "readinessProbe httpGet is path='$(jp "$c.readinessProbe.httpGet.path}")' port='$(jp "$c.readinessProbe.httpGet.port}")'"
[[ "$(jp "$c.readinessProbe.periodSeconds}")" == "5" ]] && pass "periodSeconds 5" || fail "periodSeconds is '$(jp "$c.readinessProbe.periodSeconds}")'"
[[ "$(jp '{.status.readyReplicas}')" == "2" ]] && pass "2 Pods ready" || fail "only '$(jp '{.status.readyReplicas}')' Pods ready"

exit ${FAILED}
