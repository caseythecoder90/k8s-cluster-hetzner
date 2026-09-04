#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q16:"

unchanged q16-fixed "/course4/16/base/*.yaml" "/course4/16/components/monitoring/*.yaml" && pass "base and component untouched" || fail "base or component files were modified"
$SSH_CP "grep -q '^components:' /course4/16/overlays/prod/kustomization.yaml" && pass "prod overlay lists components:" || fail "prod kustomization has no components: field"
$SSH_CP "grep -q 'components' /course4/16/overlays/dev/kustomization.yaml" && fail "dev overlay references the component too" || pass "dev overlay left without the component"

jp() { kubectl -n "$1" get deploy obsidian-app -o jsonpath="$2" 2>/dev/null; }
[[ "$(jp obsidian '{.spec.template.spec.containers[0].env[?(@.name=="METRICS_ENABLED")].value}')" == "true" ]] && pass "prod: METRICS_ENABLED=true" || fail "prod Deployment lacks env METRICS_ENABLED=true"
kubectl -n obsidian get cm monitoring-config >/dev/null 2>&1 && pass "prod: ConfigMap monitoring-config exists" || fail "ConfigMap monitoring-config missing in obsidian"
[[ "$(jp obsidian '{.status.readyReplicas}')" == "1" ]] && pass "prod Pod running" || fail "prod Pod not ready"

[[ -z "$(jp obsidian-dev '{.spec.template.spec.containers[0].env[?(@.name=="METRICS_ENABLED")].value}')" ]] && pass "dev: no METRICS_ENABLED" || fail "dev Deployment got METRICS_ENABLED — the component was enabled for dev"
kubectl -n obsidian-dev get cm monitoring-config >/dev/null 2>&1 && fail "ConfigMap monitoring-config exists in obsidian-dev" || pass "dev: no monitoring-config"

exit ${FAILED}
