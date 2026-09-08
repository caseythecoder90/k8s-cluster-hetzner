#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q16:"

unchanged q16-base "$COURSE/16/base/*.yaml" && pass "base untouched" || fail "files in /course5/16/base were modified — everything belongs in the overlay"
$SSH_CP "kubectl kustomize /course5/16/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/16/overlays/prod fails"; exit 1; }

jd() { kubectl -n mercury get deploy hg-gauge -o jsonpath="$1" 2>/dev/null; }
js() { kubectl -n mercury get svc hg-gauge -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jd '{.metadata.name}')" ]] && pass "Deployment hg-gauge in mercury" || { fail "Deployment hg-gauge not found in Namespace mercury (namespace: + namePrefix: hg-)"; exit 1; }
[[ -n "$(js '{.metadata.name}')" ]] && pass "Service hg-gauge in mercury" || fail "Service hg-gauge not found — the base contributes both manifests"

# 3 + 4 — replicas and images
[[ "$(jd '{.spec.replicas}')" == "3" ]] && pass "3 replicas" || fail "replicas is '$(jd '{.spec.replicas}')' — replicas[].name is the BASE name 'gauge'"
[[ "$(jd '{.spec.template.spec.containers[0].image}')" == "nginx:1.27-alpine" ]] && pass "image nginx:1.27-alpine" || fail "image is '$(jd '{.spec.template.spec.containers[0].image}')' — images[].name is the IMAGE 'nginx', not the container 'web'"

# 5 — labels without selectors
[[ "$(jd '{.metadata.labels.env}')" == "prod" ]] && pass "Deployment labelled env=prod" || fail "Deployment metadata label env is '$(jd '{.metadata.labels.env}')'"
[[ "$(js '{.metadata.labels.env}')" == "prod" ]] && pass "Service labelled env=prod" || fail "Service metadata label env is missing"
[[ -z "$(jd '{.spec.selector.matchLabels.env}')" ]] && pass "Deployment selector untouched" || fail "the Deployment selector now contains env — commonLabels does that, labels: does not"
[[ -z "$(js '{.spec.selector.env}')" ]] && pass "Service selector untouched" || fail "the Service selector now contains env"

# 6 — the generator and the rewritten reference
ref=$(jd '{.spec.template.spec.volumes[0].configMap.name}' || true)
[[ "$ref" == hg-gauge-config* ]] && pass "volume references the generated ConfigMap $ref" || fail "the volume references '$ref' — expected the generated hg-gauge-config; the generator's name: is the BASE's reference name 'gauge-config' and the prefix is added afterwards"
kubectl -n mercury get cm "$ref" >/dev/null 2>&1 && pass "ConfigMap $ref exists" || { fail "the Deployment references ConfigMap '$ref' but no such ConfigMap exists in mercury"; exit 1; }
jc() { kubectl -n mercury get cm "$ref" -o jsonpath="$1" 2>/dev/null; }
[[ "$(jc '{.data.UNITS}')" == "metric" ]] && pass "ConfigMap UNITS=metric" || fail "ConfigMap key UNITS is '$(jc '{.data.UNITS}')'"
[[ "$(jc '{.data.SCALE}')" == "celsius" ]] && pass "ConfigMap SCALE=celsius" || fail "ConfigMap key SCALE is '$(jc '{.data.SCALE}')'"

# 7 — the patch
ro=$(jd '{.spec.template.spec.containers[0].env[?(@.name=="READ_ONLY")].value}' || true)
md=$(jd '{.spec.template.spec.containers[0].env[?(@.name=="MODE")].value}' || true)
[[ "$ro" == "true" ]] && pass "env READ_ONLY=true" || fail "env READ_ONLY is '$ro' — env values are strings, so it must be quoted in the patch"
[[ "$md" == "gauge" ]] && pass "env MODE=gauge still present" || fail "env MODE is '$md' — the patch replaced the env list instead of adding to it"

waitdeploy mercury hg-gauge 120 || true
[[ "$(jd '{.status.readyReplicas}')" == "3" ]] && pass "3 Pods ready" || fail "only '$(jd '{.status.readyReplicas}')' Pods ready"

exit ${FAILED}
