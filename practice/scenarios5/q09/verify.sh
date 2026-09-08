#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q09:"

unchanged q09-base "$COURSE/9/base/*.yaml" && pass "base untouched" || fail "files in /course5/9/base were modified"
$SSH_CP "kubectl kustomize /course5/9/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/9/overlays/prod fails"; exit 1; }
$SSH_CP "grep -qE '^[[:space:]]*patches:' /course5/9/overlays/prod/kustomization.yaml" && pass "overlay uses patches:" || fail "no patches: field in /course5/9/overlays/prod/kustomization.yaml"

jp() { kubectl -n bronze get deploy smelter -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "Deployment smelter found in bronze" || { fail "Deployment smelter not found in Namespace bronze — was the overlay applied?"; exit 1; }

[[ "$(jp '{.spec.minReadySeconds}')" == "20" ]] && pass "spec.minReadySeconds = 20" || fail "spec.minReadySeconds is '$(jp '{.spec.minReadySeconds}')' (expected 20 — a DEPLOYMENT field, directly under /spec)"
[[ "$(jp '{.spec.template.spec.terminationGracePeriodSeconds}')" == "45" ]] && pass "pod terminationGracePeriodSeconds = 45" || fail "spec.template.spec.terminationGracePeriodSeconds is '$(jp '{.spec.template.spec.terminationGracePeriodSeconds}')' (expected 45; 30 means it is still the default — a POD field, under /spec/template/spec)"
[[ "$(jp '{.spec.template.metadata.labels.tier}')" == "smelting" ]] && pass "pod template label tier=smelting" || fail "the Pod template label tier is '$(jp '{.spec.template.metadata.labels.tier}')' (expected smelting, at /spec/template/metadata/labels)"
[[ -z "$(jp '{.metadata.labels.tier}')" ]] && pass "Deployment metadata did NOT gain tier" || fail "the Deployment's own metadata.labels has tier='$(jp '{.metadata.labels.tier}')' — that is /metadata/labels, one hop short of the Pod template. This is the silent failure: it applies cleanly and does the wrong thing"
[[ "$(jp '{.spec.template.metadata.labels.app}')" == "smelter" ]] && pass "pod label app=smelter kept" || fail "the Pod template lost its app label"
[[ "$(jp '{.spec.selector.matchLabels.tier}')" == "" ]] && pass "selector unchanged" || fail "the selector gained tier — matchLabels is immutable on a live Deployment"

ready=$(kubectl -n bronze get deploy smelter -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
[[ "$ready" == "1" ]] && pass "Pod ready" || fail "Pod not ready ('$ready') — with minReadySeconds=20 the rollout takes ~20s longer, give it a moment"

exit ${FAILED}
