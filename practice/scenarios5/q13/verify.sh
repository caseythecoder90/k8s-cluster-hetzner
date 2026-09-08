#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q13:"

unchanged q13-base "$COURSE/13/base/*.yaml" && pass "base untouched" || fail "files in /course5/13/base were modified"
$SSH_CP "kubectl kustomize /course5/13/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/13/overlays/prod fails"; exit 1; }
$SSH_CP "grep -q secretGenerator /course5/13/overlays/prod/kustomization.yaml" && pass "overlay declares a secretGenerator" || fail "no secretGenerator in /course5/13/overlays/prod/kustomization.yaml"
$SSH_CP "grep -q configMapGenerator /course5/13/overlays/prod/kustomization.yaml" && pass "overlay declares a configMapGenerator" || fail "no configMapGenerator in /course5/13/overlays/prod/kustomization.yaml"

# --- the object that must KEEP its hash -------------------------------------
jb() { kubectl -n indium get deploy broker -o jsonpath="$1" 2>/dev/null; }
sref=$(jb '{.spec.template.spec.containers[0].env[0].valueFrom.secretKeyRef.name}' || true)
[[ -n "$sref" ]] && pass "broker references Secret $sref" || { fail "Deployment broker has no secretKeyRef — was the base changed?"; exit 1; }
[[ "$sref" =~ ^broker-auth-[a-z0-9]+$ ]] && pass "the reference carries a hash suffix" || fail "broker references '$sref' — the Secret must keep its hash, so this should read broker-auth-<hash>; disableNameSuffixHash was applied too widely"
kubectl -n indium get secret "$sref" >/dev/null 2>&1 && pass "Secret $sref exists" || { fail "broker references Secret '$sref' but no such Secret exists in indium"; exit 1; }
sref2=$(jb '{.spec.template.spec.containers[0].env[1].valueFrom.secretKeyRef.name}' || true)
[[ "$sref2" == "$sref" ]] && pass "both secretKeyRefs rewritten to the same name" || fail "the two env vars point at '$sref' and '$sref2' — a single build rewrites both"
u=$(kubectl -n indium get secret "$sref" -o jsonpath='{.data.username}' 2>/dev/null | base64 -d || true)
p=$(kubectl -n indium get secret "$sref" -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)
[[ "$u" == "indium" && "$p" == "bismuth-77" ]] && pass "Secret keys username/password correct" || fail "Secret data is username='$u' password='$p'"
t=$(kubectl -n indium get secret "$sref" -o jsonpath='{.type}' 2>/dev/null || true)
[[ "$t" == "Opaque" ]] && pass "Secret type Opaque" || fail "Secret type is '$t'"
kubectl -n indium get secret broker-auth >/dev/null 2>&1 \
  && fail "a Secret named exactly 'broker-auth' also exists — either the hash was disabled, or it is a leftover from an earlier apply (apply -k never prunes: kubectl delete it)" \
  || pass "no un-hashed broker-auth Secret"

# --- the object that must have an EXACT name --------------------------------
kubectl -n indium get cm broker-rules >/dev/null 2>&1 && pass "ConfigMap named exactly broker-rules" || { fail "no ConfigMap named exactly 'broker-rules' in indium — audit mounts it by that name, so this generator needs options.disableNameSuffixHash: true"; exit 1; }
rules=$(kubectl -n indium get cm broker-rules -o jsonpath='{.data.rules\.conf}' 2>/dev/null || true)
[[ "$rules" == *"max_message_bytes=65536"* ]] && pass "key rules.conf holds the file contents" || fail "ConfigMap key rules.conf is missing or wrong (found: '$rules')"
extra=$(kubectl -n indium get cm -o name 2>/dev/null | grep -c 'configmap/broker-rules-' || true)
[[ "$extra" == "0" ]] && pass "no hashed broker-rules-* ConfigMap left behind" || fail "$extra hashed broker-rules-* ConfigMap(s) also exist — a leftover from an earlier apply; apply -k never prunes"

# --- the thing outside the build must not have been touched -----------------
aref=$(kubectl -n indium get deploy audit -o jsonpath='{.spec.template.spec.volumes[0].configMap.name}' 2>/dev/null || true)
[[ "$aref" == "broker-rules" ]] && pass "audit still asks for the fixed name broker-rules" || fail "audit's volume now references '$aref' — the auditor is outside your build and must not be edited; the generator has to match its name instead"

waitdeploy indium broker 90 || true
waitdeploy indium audit 90 || true
[[ "$(jb '{.status.readyReplicas}')" == "1" ]] && pass "broker running" || fail "broker not ready"
[[ "$(kubectl -n indium get deploy audit -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" == "1" ]] && pass "audit running" || fail "audit not ready — it stays ContainerCreating until a ConfigMap called exactly broker-rules exists"

exit ${FAILED}
