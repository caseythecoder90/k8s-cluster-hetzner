#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q06:"

sjp()   { kubectl -n jordan get svc jordan-api -o jsonpath="$1" 2>/dev/null || true; }
podip() { kubectl -n jordan get pod -l "$1" -o jsonpath='{.items[0].status.podIP}' 2>/dev/null || true; }

$SSH_CP "test -s /course6/6/policy.yaml" && pass "/course6/6/policy.yaml saved" || fail "/course6/6/policy.yaml is missing or empty — the task asks for the manifest on disk"

[[ -n "$(kubectl -n jordan get netpol allow-frontend -o jsonpath='{.metadata.name}' 2>/dev/null || true)" ]] \
  && pass "NetworkPolicy allow-frontend exists in jordan" \
  || { fail "no NetworkPolicy 'allow-frontend' in Namespace jordan"; exit 1; }

# The environment must be intact, or "blocked" would prove nothing.
[[ "$(kubectl -n jordan get deploy jordan-api -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)" == "1" ]] \
  && pass "jordan-api Pod still Ready" || fail "jordan-api is not Ready — the Deployment must not be changed"
[[ "$(sjp '{.spec.ports[?(@.name=="api")].targetPort}')"   == "8080" ]] && pass "Service port 80 -> container 8080 intact"   || fail "the Service's 'api' port no longer targets 8080 — the Service must not be changed"
[[ "$(sjp '{.spec.ports[?(@.name=="admin")].targetPort}')" == "9090" ]] && pass "Service port 9090 -> container 9090 intact" || fail "the Service's 'admin' port is gone or altered — blocking the admin port by deleting it is not the answer"

apiip=$(podip app=jordan-api)
[[ -n "$apiip" ]] && pass "jordan-api Pod has an IP ($apiip)" || { fail "no Running jordan-api Pod found — re-run setup.sh"; exit 1; }
svc=$(svcip jordan jordan-api || true)
[[ -n "$svc" ]] && pass "Service jordan-api has a ClusterIP ($svc)" || { fail "Service jordan-api has no ClusterIP"; exit 1; }

# 1. the allowed client, on the allowed port — through the Service (the real path)
reach jordan frontend "http://$svc:80" \
  && pass "allowed: frontend reaches the app through the Service on :80" \
  || fail "frontend cannot reach http://$svc:80 — the Service's port 80 lands on container port 8080, and 8080 is the number the policy must name"

# 2. the allowed client, straight at the Pod on the allowed port
reach jordan frontend "http://$apiip:8080" \
  && pass "allowed: frontend reaches the Pod on 8080" \
  || fail "frontend cannot reach the Pod on $apiip:8080 — check the from: podSelector matches role=frontend and the port is 8080"

# 3. the allowed client, on the port that must stay shut
reach jordan frontend "http://$apiip:9090" \
  && fail "frontend STILL reaches the admin port $apiip:9090 — a rule with no ports: allows EVERY port; name port 8080 explicitly" \
  || pass "blocked: frontend cannot reach the admin port 9090"

# 4. the wrong client, on the allowed port
reach jordan batch "http://$apiip:8080" \
  && fail "batch STILL reaches $apiip:8080 — the from: peer is matching more than role=frontend (an empty podSelector {} means every Pod in the Namespace)" \
  || pass "blocked: batch cannot reach the app port"

# 5. the wrong client, on the admin port
reach jordan batch "http://$apiip:9090" \
  && fail "batch STILL reaches the admin port $apiip:9090" \
  || pass "blocked: batch cannot reach the admin port either"

exit ${FAILED}
