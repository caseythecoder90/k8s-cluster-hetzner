#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q10:"

unchanged q10-base "/course4/10/base/*.yaml" && pass "base untouched" || fail "files in /course4/10/base were modified"
$SSH_CP "kubectl kustomize /course4/10/overlays/staging >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course4/10/overlays/staging fails (or the directory is missing)"; exit 1; }

jp() { kubectl -n zircon get deploy stg-web -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "Deployment stg-web in zircon (namespace + prefix)" || { fail "Deployment stg-web not found in Namespace zircon"; exit 1; }
[[ "$(jp '{.spec.replicas}')" == "2" ]] && pass "2 replicas" || fail "replicas is '$(jp '{.spec.replicas}')'"
img=$(jp '{.spec.template.spec.containers[0].image}')
[[ "$img" == "nginx:1.27-alpine" ]] && pass "image nginx:1.27-alpine" || fail "image is '$img'"
[[ "$(jp '{.metadata.labels.env}')" == "staging" ]] && pass "Deployment labelled env=staging" || fail "Deployment lacks label env=staging"
[[ -z "$(jp '{.spec.selector.matchLabels.env}')" ]] && pass "Deployment selector untouched" || fail "env label leaked into the Deployment selector (commonLabels does that — use labels: with includeSelectors false)"

svc_env=$(kubectl -n zircon get svc stg-web -o jsonpath='{.metadata.labels.env}' 2>/dev/null)
svc_sel=$(kubectl -n zircon get svc stg-web -o jsonpath='{.spec.selector}' 2>/dev/null)
[[ "$svc_env" == "staging" ]] && pass "Service stg-web labelled env=staging" || fail "Service stg-web missing (prefix?) or lacks label env=staging"
[[ "$svc_sel" == '{"app":"web"}' ]] && pass "Service selector untouched" || fail "Service selector is '$svc_sel' (expected only app=web)"

eps=$(kubectl -n zircon get endpoints stg-web -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w)
[[ "$eps" == "2" ]] && pass "Service has 2 endpoints" || fail "Service has $eps endpoints (expected 2)"
kubectl -n zircon get deploy web >/dev/null 2>&1 && fail "an unprefixed Deployment 'web' exists in zircon — the base was applied directly?" || pass "no unprefixed resources"

exit ${FAILED}
