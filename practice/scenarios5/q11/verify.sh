#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q11:"

unchanged q11-base "$COURSE/11/base/*.yaml" && pass "base untouched" || fail "files in /course5/11/base were modified"
$SSH_CP "kubectl kustomize /course5/11/overlays/prod >/dev/null 2>&1" && pass "overlay renders" || { fail "kubectl kustomize /course5/11/overlays/prod fails — a 'remove' on a path that does not resolve kills the whole build, and an unescaped '/' in a key never resolves"; exit 1; }
$SSH_CP "grep -rqE '^[[:space:]]*- op: *(add|replace|remove)' /course5/11/overlays/" && pass "JSON 6902 ops found" || fail "no JSON 6902 operations (- op: ...) in /course5/11/overlays"
$SSH_CP "grep -rqE 'apiVersion: *apps/v1' /course5/11/overlays/" && fail "a strategic merge patch (apiVersion: apps/v1) is present — this question is JSON 6902 only, escaping is the whole point" || pass "no strategic merge patch"

jp() { kubectl -n brass get deploy bell -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "Deployment bell found in brass" || { fail "Deployment bell not found in Namespace brass — apply the overlay (note the API server also rejects the 'brass.io/cost~center' key outright, so nothing applies until it is gone)"; exit 1; }

labels=$(jp '{.metadata.labels}' || true)
anns=$(jp '{.metadata.annotations}' || true)

echo "$labels" | grep -qF '"app.kubernetes.io/managed-by":"kustomize"' && pass "label app.kubernetes.io/managed-by=kustomize" || fail "labels are $labels — expected app.kubernetes.io/managed-by=kustomize (path: /metadata/labels/app.kubernetes.io~1managed-by; the dots are NOT escaped, only the slash)"
echo "$labels" | grep -qF '"app":"bell"' && pass "label app=bell kept" || fail "label app=bell is gone — point at the key, not at the whole /metadata/labels map"

echo "$anns" | grep -qF 'rewrite-target' && fail "annotation nginx.ingress.kubernetes.io/rewrite-target is still present — the slash in the key must be written ~1: /metadata/annotations/nginx.ingress.kubernetes.io~1rewrite-target" || pass "annotation nginx.ingress.kubernetes.io/rewrite-target removed"
echo "$anns" | grep -qF 'cost~center' && fail "annotation brass.io/cost~center is still present — that key needs BOTH escapes: ~ first (~0), then / (~1), giving brass.io~1cost~0center" || pass "annotation brass.io/cost~center removed"
echo "$anns" | grep -qF '"brass.io/team":"brass"' && pass "annotation brass.io/team kept" || fail "annotations are $anns — brass.io/team was removed too"
echo "$anns" | grep -qF '"app.kubernetes.io/version":"2.1.0"' && pass "annotation app.kubernetes.io/version=2.1.0 added" || fail "annotations are $anns — expected app.kubernetes.io/version=\"2.1.0\" (escape the slash in the path; inside a value: the key is written verbatim)"

[[ "$(jp '{.spec.template.spec.containers[0].image}')" == "nginx:1-alpine" ]] && pass "container untouched" || fail "the container was modified — this question is metadata only"
[[ "$(jp '{.status.readyReplicas}')" == "1" ]] && pass "Deployment ready" || fail "Deployment not ready — kubectl -n brass get pods"

exit ${FAILED}
