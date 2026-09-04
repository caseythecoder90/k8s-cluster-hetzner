#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "p2:"
jp() { kubectl -n nike get deploy nike-web -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "deployment exists" || { fail "nike-web not found"; exit 1; }
[[ "$(jp '{.spec.replicas}')" == "3" ]] && pass "replicas patched to 3" || fail "replicas is '$(jp '{.spec.replicas}')'"
env=$(jp '{.metadata.labels.env}')
[[ "$env" == "production" ]] && pass "common label env=production present" || fail "env label is '$env'"
img=$(jp '{.spec.template.spec.containers[0].image}')
[[ "$img" == "nginx:1.27-alpine" ]] && pass "image tag overridden" || fail "image is '$img'"
svc_env=$(kubectl -n nike get svc nike-svc -o jsonpath='{.metadata.labels.env}' 2>/dev/null)
[[ "$svc_env" == "production" ]] && pass "common label also applied to the Service" || fail "Service missing the common label — labels transformer should hit every resource"
avail=$(jp '{.status.availableReplicas}')
[[ "$avail" == "3" ]] && pass "3 pods available" || fail "pods not all available"
exit ${FAILED}
