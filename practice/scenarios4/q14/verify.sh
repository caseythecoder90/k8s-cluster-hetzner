#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q14:"

unchanged q14-manifests /course4/14/base/deployment.yaml /course4/14/base/service.yaml \
  && pass "manifests untouched (same names, same content)" \
  || fail "deployment.yaml / service.yaml were modified or renamed"
$SSH_CP "kubectl kustomize /course4/14/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || fail "kubectl kustomize /course4/14/overlays/prod still fails"

jp() { kubectl -n slate get deploy slate-web -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "Deployment slate-web in slate" || { fail "Deployment slate-web not found in Namespace slate"; exit 1; }
[[ "$(jp '{.spec.replicas}')" == "2" ]] && pass "2 replicas" || fail "replicas is '$(jp '{.spec.replicas}')'"
[[ "$(jp '{.status.readyReplicas}')" == "2" ]] && pass "2 Pods ready" || fail "only '$(jp '{.status.readyReplicas}')' Pods ready"
[[ "$(jp '{.metadata.labels.team}')" == "slate" ]] && pass "Deployment labelled team=slate" || fail "Deployment lacks label team=slate"
svc=$(kubectl -n slate get svc slate-web -o jsonpath='{.metadata.labels.team}' 2>/dev/null)
[[ "$svc" == "slate" ]] && pass "Service labelled team=slate" || fail "Service slate-web missing or lacks label team=slate"

exit ${FAILED}
