#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q05:"

jp()    { kubectl -n indus get netpol default-deny-ingress -o jsonpath="$1" 2>/dev/null || true; }
podip() { kubectl -n indus get pod -l "$1" -o jsonpath='{.items[0].status.podIP}' 2>/dev/null || true; }

$SSH_CP "test -s /course6/5/policy.yaml" && pass "/course6/5/policy.yaml saved" || fail "/course6/5/policy.yaml is missing or empty — the task asks for the manifest on disk"

[[ -n "$(jp '{.metadata.name}')" ]] && pass "NetworkPolicy default-deny-ingress exists in indus" || { fail "no NetworkPolicy 'default-deny-ingress' in Namespace indus"; exit 1; }

ps=$(jp '{.spec.podSelector}')
[[ "$ps" == "{}" ]] && pass "podSelector: {} — every Pod in the Namespace" || fail "spec.podSelector is '$ps' (expected an empty selector {}, which is the only way to mean 'all Pods, including ones created later')"

pt=$(jp '{.spec.policyTypes[*]}')
[[ "$pt" == "Ingress" ]] && pass "policyTypes: [Ingress] only" || fail "spec.policyTypes is '$pt' (expected exactly 'Ingress' — listing Egress here makes egress default-deny too and kills DNS)"

[[ -z "$(jp '{.spec.ingress[0]}')" ]] && pass "no ingress rules — nothing is allowed back in" || fail "the policy carries an ingress rule; a default-deny has no rules at all"
[[ -z "$(jp '{.spec.egress[0]}')" ]] && pass "no egress rules — egress is untouched" || fail "the policy carries an egress rule; this question must not restrict egress"

webip=$(podip app=indus-web)
[[ -n "$webip" ]] && pass "indus-web Pod has an IP ($webip)" || { fail "no Running indus-web Pod found — re-run setup.sh"; exit 1; }

reach indus indus-client "http://$webip:80" && fail "indus-client STILL reaches indus-web on $webip:80 — ingress is not being denied" || pass "ingress blocked: indus-client cannot reach indus-web"

kubectl -n indus exec deploy/indus-client -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1 \
  && pass "egress still open: indus-client resolves kubernetes.default via CoreDNS in kube-system" \
  || fail "indus-client can no longer resolve DNS — you have restricted egress as well; a NetworkPolicy only affects a direction that is named in policyTypes"

kubectl -n indus exec deploy/indus-client -- nslookup kube-dns.kube-system.svc.cluster.local >/dev/null 2>&1 \
  && pass "egress still open: a second DNS query leaves the Namespace fine" \
  || fail "DNS out of indus is broken — check that policyTypes lists Ingress and nothing else"

exit ${FAILED}
