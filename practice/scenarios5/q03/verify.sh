#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q03:"

unchanged q03-base "$COURSE/3/base/*.yaml" && pass "base untouched" || fail "files in /course5/3/base were modified"
$SSH_CP "kubectl kustomize /course5/3/overlays/labelled >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/3/overlays/labelled fails"; exit 1; }

jd() { kubectl -n cobalt get deploy portal -o jsonpath="$1" 2>/dev/null; }
js() { kubectl -n cobalt get svc portal -o jsonpath="$1" 2>/dev/null; }
[[ "$(jd '{.metadata.labels.tier}')" == "frontend" ]] && pass "Deployment labelled tier=frontend" || fail "Deployment metadata label tier is '$(jd '{.metadata.labels.tier}')' — was the overlay applied?"
[[ "$(js '{.metadata.labels.tier}')" == "frontend" ]] && pass "Service labelled tier=frontend" || fail "Service metadata label tier is missing"
[[ -z "$(jd '{.spec.selector.matchLabels.tier}')" ]] && pass "Deployment selector untouched" || fail "Deployment selector now contains tier — commonLabels does that, labels: does not"
[[ -z "$(js '{.spec.selector.tier}')" ]] && pass "Service selector untouched" || fail "Service selector now contains tier"
[[ "$(jd '{.status.readyReplicas}')" == "2" ]] && pass "2 Pods still ready" || fail "only '$(jd '{.status.readyReplicas}')' Pods ready"

exit ${FAILED}
