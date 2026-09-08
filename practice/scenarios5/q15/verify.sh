#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q15:"

unchanged q15-base "$COURSE/15/base/*.yaml" && pass "base untouched" || fail "files in /course5/15/base were modified — all three fixes belong in the overlay"
$SSH_CP "test -f /course5/15/overlays/staging/app.conf" && pass "app.conf still on disk under its own name" || fail "/course5/15/overlays/staging/app.conf is gone — the file name was right; the reference to it was not"
$SSH_CP "test -e /course5/15/overlays/staging/app.config" \
  && fail "an app.config was created on disk — fix the kustomization's files: entry instead, the task forbids creating or renaming files" \
  || pass "no app.config was created on disk"
$SSH_CP "kubectl kustomize /course5/15/overlays/staging >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/15/overlays/staging still fails — run it and read the next error"; exit 1; }

jd() { kubectl -n cadmium get deploy stg-pigment -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jd '{.metadata.name}')" ]] && pass "Deployment stg-pigment in cadmium" || { fail "Deployment stg-pigment not found in Namespace cadmium — did you apply the overlay?"; exit 1; }
[[ "$(jd '{.spec.replicas}')" == "2" ]] && pass "2 replicas" || fail "replicas is '$(jd '{.spec.replicas}')' — replicas[].name is the BASE name 'pigment', not 'stg-pigment'"
[[ -n "$(kubectl -n cadmium get svc stg-pigment -o jsonpath='{.metadata.name}' 2>/dev/null)" ]] && pass "Service stg-pigment in cadmium" || fail "Service stg-pigment not found — the base contributes both manifests"

ref=$(jd '{.spec.template.spec.volumes[0].configMap.name}' || true)
[[ "$ref" == stg-pigment-config* ]] && pass "volume references the generated ConfigMap $ref" || fail "the volume references '$ref' — expected the generated stg-pigment-config (namePrefix applies to generated objects too, and the reference is rewritten for you)"
kubectl -n cadmium get cm "$ref" >/dev/null 2>&1 && pass "ConfigMap $ref exists" || { fail "the Deployment references ConfigMap '$ref' but no such ConfigMap exists in cadmium"; exit 1; }
conf=$(kubectl -n cadmium get cm "$ref" -o jsonpath='{.data.app\.conf}' 2>/dev/null || true)
[[ "$conf" == *"palette=cadmium"* ]] && pass "key app.conf holds the file contents" || fail "ConfigMap key app.conf is missing or wrong (found: '$conf')"

waitdeploy cadmium stg-pigment 90 || true
[[ "$(jd '{.status.readyReplicas}')" == "2" ]] && pass "2 Pods ready" || fail "only '$(jd '{.status.readyReplicas}')' Pods ready"

exit ${FAILED}
