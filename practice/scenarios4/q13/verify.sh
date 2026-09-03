#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q13:"

unchanged q13-base "/course4/13/base/*.yaml" && pass "base untouched" || fail "files in /course4/13/base were modified"
kz=$($SSH_CP "cat /course4/13/overlays/prod/kustomization.yaml 2>/dev/null" || true)
echo "$kz" | grep -q "configMapGenerator" && pass "kustomization has a configMapGenerator" || fail "no configMapGenerator in the prod kustomization"
echo "$kz" | grep -q "secretGenerator" && pass "kustomization has a secretGenerator" || fail "no secretGenerator in the prod kustomization"

cm=$(kubectl -n lapis get cm -o name 2>/dev/null | sed 's#configmap/##' | grep -E '^app-config(-[a-z0-9]+)?$' | head -1)
[[ -n "$cm" ]] && pass "ConfigMap $cm exists" || { fail "no ConfigMap app-config (with or without hash) in lapis"; exit 1; }
props=$(kubectl -n lapis get cm "$cm" -o jsonpath='{.data.app\.properties}' 2>/dev/null)
echo "$props" | grep -q "color=blue" && pass "key app.properties holds the file content" || fail "ConfigMap key app.properties missing or wrong (found: '$props')"
ll=$(kubectl -n lapis get cm "$cm" -o jsonpath='{.data.LOG_LEVEL}' 2>/dev/null)
[[ "$ll" == "warn" ]] && pass "key LOG_LEVEL=warn" || fail "ConfigMap key LOG_LEVEL is '$ll'"

kubectl -n lapis get secret db-creds >/dev/null 2>&1 && pass "Secret named exactly db-creds" || fail "no Secret named exactly db-creds (disableNameSuffixHash?)"
u=$(kubectl -n lapis get secret db-creds -o jsonpath='{.data.username}' 2>/dev/null | base64 -d)
p=$(kubectl -n lapis get secret db-creds -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)
[[ "$u" == "lapis" && "$p" == "ruby-lapis-42" ]] && pass "Secret keys username/password correct" || fail "Secret data is username='$u' password='$p'"
extra=$(kubectl -n lapis get secret -o name 2>/dev/null | grep -c 'secret/db-creds-' || true)
[[ "$extra" == "0" ]] && pass "no hashed db-creds-* Secret left behind" || fail "a hashed db-creds-* Secret also exists"

ref=$(kubectl -n lapis get deploy lapis-app -o jsonpath='{.spec.template.spec.volumes[0].configMap.name}' 2>/dev/null)
[[ "$ref" == "$cm" ]] && pass "Deployment references the generated ConfigMap ($ref)" || fail "Deployment volume references '$ref' but the ConfigMap is '$cm'"
ready=$(kubectl -n lapis get deploy lapis-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[[ "$ready" == "1" ]] && pass "Pod running" || fail "Pod not ready"

exit ${FAILED}
