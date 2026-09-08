#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q12:"

unchanged q12-base "$COURSE/12/base/*.yaml" && pass "base untouched" || fail "files in /course5/12/base were modified"
$SSH_CP "kubectl kustomize /course5/12/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/12/overlays/prod fails"; exit 1; }
$SSH_CP "grep -q configMapGenerator /course5/12/overlays/prod/kustomization.yaml" && pass "overlay declares a configMapGenerator" || fail "no configMapGenerator in /course5/12/overlays/prod/kustomization.yaml"

jd() { kubectl -n gallium get deploy renderer -o jsonpath="$1" 2>/dev/null; }
ref=$(jd '{.spec.template.spec.volumes[0].configMap.name}' || true)
[[ -n "$ref" ]] && pass "Deployment volume references ConfigMap $ref" || { fail "Deployment renderer has no configMap volume in gallium — was the base changed, or the overlay never applied?"; exit 1; }
kubectl -n gallium get cm "$ref" >/dev/null 2>&1 && pass "ConfigMap $ref exists" || { fail "the Deployment references ConfigMap '$ref' but no such ConfigMap exists in gallium — generate it and re-apply the overlay"; exit 1; }
[[ "$ref" == gallium-config* ]] && pass "the generated ConfigMap is gallium-config" || fail "the referenced ConfigMap is '$ref' — the generator's name: must be gallium-config so the base's references are rewritten"
envref=$(jd '{.spec.template.spec.containers[0].env[0].valueFrom.configMapKeyRef.name}' || true)
[[ "$envref" == "$ref" ]] && pass "configMapKeyRef rewritten to the same name" || fail "the env var points at '$envref' but the volume at '$ref' — one build rewrites both, so a hand-typed name is the only way they differ"

jc() { kubectl -n gallium get cm "$ref" -o jsonpath="$1" 2>/dev/null; }
[[ "$(jc '{.data.app\.properties}')" == *"color=teal"* ]] && pass "key app.properties holds the file contents" || fail "key app.properties is '$(jc '{.data.app\.properties}')' — under files: the key is the file's own name"
[[ "$(jc '{.data.index\.html}')" == *"Gallium"* ]] && pass "key index.html holds content/landing.html" || fail "key index.html is missing — the rename form is 'index.html=content/landing.html' under files:"
[[ -z "$(jc '{.data.landing\.html}')" ]] && pass "no landing.html key" || fail "the HTML arrived under the key 'landing.html' — key=path renames it to index.html"
[[ "$(jc '{.data.LOG_LEVEL}')" == "warn" ]] && pass "key LOG_LEVEL=warn" || fail "key LOG_LEVEL is '$(jc '{.data.LOG_LEVEL}')' — it comes from literals:, not from a file"
[[ "$(jc '{.data.MAX_CONNECTIONS}')" == "64" ]] && pass "key MAX_CONNECTIONS=64" || fail "key MAX_CONNECTIONS is '$(jc '{.data.MAX_CONNECTIONS}')'"
[[ "$(jc '{.data.CACHE_TTL}')" == "300" ]] && pass "key CACHE_TTL=300" || fail "key CACHE_TTL is '$(jc '{.data.CACHE_TTL}')'"
[[ -z "$(jc '{.data.runtime\.env}')" ]] && pass "runtime.env was expanded into keys, not stored whole" || fail "there is a key literally called 'runtime.env' — that is what files: does; one key per KEY=VALUE line is envs:"

waitdeploy gallium renderer 90 || true
[[ "$(jd '{.status.readyReplicas}')" == "1" ]] && pass "Pod running" || fail "Pod not ready — 'kubectl -n gallium describe pod' names the missing ConfigMap or the missing key"

exit ${FAILED}
