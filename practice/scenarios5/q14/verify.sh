#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q14:"

unchanged q14-base "$COURSE/14/base/*.yaml" && pass "base untouched (manifests and its generators)" || fail "files in /course5/14/base were modified — the generators live in the base kustomization and must stay there"
$SSH_CP "kubectl kustomize /course5/14/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/14/overlays/prod fails — declaring a generator the base already declares needs behavior:"; exit 1; }
$SSH_CP "grep -rq 'REGION\|TIMEOUT' /course5/14/overlays/prod/" \
  && fail "REGION or TIMEOUT appears in the overlay — those keys must survive from the base, not be retyped (that is what behavior: merge is for)" \
  || pass "the overlay does not restate the base's keys"

jd() { kubectl -n osmium get deploy catalog -o jsonpath="$1" 2>/dev/null; }
s=$(jd '{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' || true)
f=$(jd '{.spec.template.spec.containers[0].envFrom[1].configMapRef.name}' || true)
[[ -n "$s" && -n "$f" ]] && pass "catalog references ConfigMaps $s and $f" || { fail "Deployment catalog's envFrom is missing (found '$s' / '$f') — was the base changed?"; exit 1; }
[[ "$s" == app-settings* && "$f" == feature-flags* ]] && pass "both references still resolve to the base's generator names" || fail "catalog now points at '$s' and '$f' — an override must reuse the base's generator name, otherwise nothing references it"
kubectl -n osmium get cm "$s" >/dev/null 2>&1 && kubectl -n osmium get cm "$f" >/dev/null 2>&1 && pass "both ConfigMaps exist" || { fail "catalog references a ConfigMap that does not exist in osmium — re-apply the overlay"; exit 1; }

# --- app-settings: merge (base keys must survive) ---------------------------
ja() { kubectl -n osmium get cm "$s" -o jsonpath="$1" 2>/dev/null; }
[[ "$(ja '{.data.LOG_LEVEL}')" == "debug" ]] && pass "app-settings LOG_LEVEL=debug (overridden)" || fail "LOG_LEVEL is '$(ja '{.data.LOG_LEVEL}')', expected debug"
[[ "$(ja '{.data.TRACE_SAMPLING}')" == "0.5" ]] && pass "app-settings TRACE_SAMPLING=0.5 (added)" || fail "TRACE_SAMPLING is '$(ja '{.data.TRACE_SAMPLING}')', expected 0.5"
[[ "$(ja '{.data.REGION}')" == "eu-west" ]] && pass "app-settings REGION=eu-west survived from the base" || fail "REGION is '$(ja '{.data.REGION}')' — the base's keys were dropped, so this generator was replaced when it should have been merged"
[[ "$(ja '{.data.TIMEOUT}')" == "30" ]] && pass "app-settings TIMEOUT=30 survived from the base" || fail "TIMEOUT is '$(ja '{.data.TIMEOUT}')' — the base's keys were dropped, so this generator was replaced when it should have been merged"

# --- feature-flags: replace (a base key must be gone) -----------------------
jf() { kubectl -n osmium get cm "$f" -o jsonpath="$1" 2>/dev/null; }
[[ "$(jf '{.data.beta_ui}')" == "true" ]] && pass "feature-flags beta_ui=true" || fail "beta_ui is '$(jf '{.data.beta_ui}')', expected true"
[[ "$(jf '{.data.dark_mode}')" == "true" ]] && pass "feature-flags dark_mode=true" || fail "dark_mode is '$(jf '{.data.dark_mode}')', expected true"
[[ -z "$(jf '{.data.new_billing}')" ]] && pass "feature-flags new_billing is gone" || fail "new_billing is still '$(jf '{.data.new_billing}')' — merge cannot delete a key, only replace drops the base's set"

waitdeploy osmium catalog 90 || true
[[ "$(jd '{.status.readyReplicas}')" == "1" ]] && pass "catalog running" || fail "catalog not ready"

exit ${FAILED}
