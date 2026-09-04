#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q15:"

unchanged q15-base "/course4/15/base/*.yaml" && pass "base untouched" || fail "files in /course4/15/base were modified"

kubectl get ns amethyst-dev >/dev/null 2>&1 && pass "Namespace amethyst-dev still exists" || fail "Namespace amethyst-dev was deleted — the task said remove the resources, not the Namespace"
left=$(kubectl -n amethyst-dev get deploy,svc --no-headers 2>/dev/null | wc -l)
[[ "$left" == "0" ]] && pass "nothing left in amethyst-dev" || fail "$left Deployment/Service objects still in amethyst-dev"

kz=$($SSH_CP "cat /course4/15/overlays/prod/kustomization.yaml 2>/dev/null" || true)
echo "$kz" | grep -q "^images:" && pass "prod overlay uses images:" || fail "no images: transformer in the prod kustomization"
echo "$kz" | grep -q "^replicas:" && pass "prod overlay uses replicas:" || fail "no replicas: field in the prod kustomization"
echo "$kz" | grep -q "^patches" && fail "prod overlay uses patches — the task asked for images/replicas" || pass "no patches used"

jp() { kubectl -n amethyst get deploy "$1" -o jsonpath="$2" 2>/dev/null; }
[[ "$(jp web '{.spec.template.spec.containers[0].image}')" == "nginx:1.27-alpine" ]] && pass "web image nginx:1.27-alpine" || fail "web image is '$(jp web '{.spec.template.spec.containers[0].image}')'"
[[ "$(jp cache '{.spec.template.spec.containers[0].image}')" == "redis:7.2-alpine" ]] && pass "cache image redis:7.2-alpine" || fail "cache image is '$(jp cache '{.spec.template.spec.containers[0].image}')'"
[[ "$(jp web '{.spec.replicas}')" == "3" ]] && pass "web 3 replicas" || fail "web replicas is '$(jp web '{.spec.replicas}')'"
[[ "$(jp cache '{.spec.replicas}')" == "1" ]] && pass "cache 1 replica" || fail "cache replicas is '$(jp cache '{.spec.replicas}')'"
[[ "$(jp web '{.status.readyReplicas}')" == "3" && "$(jp cache '{.status.readyReplicas}')" == "1" ]] && pass "all prod Pods ready" || fail "prod Pods not all ready (web $(jp web '{.status.readyReplicas}')/3, cache $(jp cache '{.status.readyReplicas}')/1)"
kubectl -n amethyst get svc web cache >/dev/null 2>&1 && pass "prod Services exist" || fail "Services web/cache missing in amethyst"

exit ${FAILED}
