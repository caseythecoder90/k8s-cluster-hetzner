#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q12:"
jp() { kubectl -n demeter get networkpolicy demeter-backend-policy -o jsonpath="$1" 2>/dev/null; }
[[ -n "$(jp '{.metadata.name}')" ]] && pass "networkpolicy exists" || { fail "demeter-backend-policy not found"; exit 1; }
sel=$(jp '{.spec.podSelector.matchLabels.app}')
[[ "$sel" == "backend" ]] && pass "podSelector targets app=backend" || fail "podSelector is wrong"
fromsel=$(jp '{.spec.ingress[0].from[0].podSelector.matchLabels.app}')
[[ "$fromsel" == "frontend" ]] && pass "allows from app=frontend" || fail "ingress 'from' selector wrong"
port=$(jp '{.spec.ingress[0].ports[0].port}')
[[ "$port" == "80" ]] && pass "restricted to port 80" || fail "port is '$port'"

echo "  (live traffic test — may take a few seconds)"
allowed=$(kubectl -n demeter exec deploy/demeter-frontend -- wget -qO- --timeout=5 http://demeter-backend-svc 2>&1 | head -c 50)
[[ "$allowed" == *"<html"* || "$allowed" == *"Welcome"* ]] && pass "frontend CAN reach backend" || fail "frontend blocked (should be allowed): $allowed"
denied=$(kubectl -n demeter-other exec demeter-other-client -- wget -qO- --timeout=5 "http://demeter-backend-svc.demeter.svc.cluster.local" 2>&1 | head -c 80)
[[ "$denied" == *"html"* ]] && fail "unrelated pod CAN reach backend — policy not blocking" || pass "unrelated pod correctly blocked"
exit ${FAILED}
