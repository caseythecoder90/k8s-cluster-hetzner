#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q08:"

podip() { kubectl -n "$1" get pod -l "$2" -o jsonpath='{.items[0].status.podIP}' 2>/dev/null || true; }

$SSH_CP "test -s /course6/8/policy.yaml" && pass "/course6/8/policy.yaml saved" || fail "/course6/8/policy.yaml is missing or empty — the task asks for the manifest on disk"

np=$(kubectl -n oder get netpol allow-rhine-web -o json 2>/dev/null || true)
[[ -n "$np" ]] && pass "NetworkPolicy allow-rhine-web exists in oder" || { fail "no NetworkPolicy 'allow-rhine-web' in Namespace oder"; exit 1; }

echo "$np" | tr -d ' \n' | grep -q '"kubernetes.io/metadata.name":"rhine"' \
  && pass "rhine is selected by its automatic kubernetes.io/metadata.name label" \
  || fail "the policy does not select the Namespace with kubernetes.io/metadata.name=rhine"

apiip=$(podip oder app=oder-api)
[[ -n "$apiip" ]] && pass "oder-api Pod has an IP ($apiip)" || { fail "no Running oder-api Pod found — re-run setup.sh"; exit 1; }

reach rhine rhine-web "http://$apiip:80" \
  && pass "allowed: rhine-web (role=web, in rhine) reaches oder-api" \
  || fail "rhine-web cannot reach $apiip:80 — an intersection needs BOTH selectors in ONE from: item; if you wrote only a podSelector it is looking inside oder, not rhine"

reach rhine rhine-batch "http://$apiip:80" \
  && fail "rhine-batch STILL reaches $apiip:80 — it is in rhine but labelled role=batch, so it can only have matched a namespaceSelector standing on its own. Two '-' items under from: are OR-ed; make them two fields of a SINGLE item." \
  || pass "blocked: rhine-batch (right Namespace, wrong label)"

reach oder oder-web "http://$apiip:80" \
  && fail "oder-web STILL reaches $apiip:80 — it is labelled role=web but lives in oder, so it can only have matched a podSelector standing on its own (a from: podSelector defaults to the policy's own Namespace). Drop the second '-' so both selectors describe ONE peer." \
  || pass "blocked: oder-web (right label, wrong Namespace)"

exit ${FAILED}
