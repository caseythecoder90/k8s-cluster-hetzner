#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q01:"

jp() { kubectl -n amazon get "$1" "$2" -o jsonpath="$3" 2>/dev/null || true; }

[[ -n "$(jp svc amazon-web '{.metadata.name}')" ]] && pass "Service amazon-web exists" || { fail "Service amazon-web not found in Namespace amazon"; exit 1; }

lbl=$(jp deploy amazon-web '{.spec.template.metadata.labels.app}')
[[ "$lbl" == "amazon-web" ]] && pass "Pod label app=amazon-web unchanged" || fail "the Pod template label app is now '$lbl' — the task says fix the Service, not the Deployment"
rr=$(jp deploy amazon-web '{.status.readyReplicas}')
[[ "$rr" == "2" ]] && pass "both amazon-web Pods still Ready" || fail "amazon-web has '$rr' ready Pods (expected 2)"

st=$(jp svc amazon-web '{.spec.type}')
[[ "$st" == "ClusterIP" ]] && pass "Service is still ClusterIP" || fail "Service type is '$st' (expected ClusterIP)"
p=$(jp svc amazon-web '{.spec.ports[0].port}')
[[ "$p" == "80" ]] && pass "Service port 80" || fail "Service port is '$p' (expected 80)"
sel=$(jp svc amazon-web '{.spec.selector.app}')
[[ "$sel" == "amazon-web" ]] && pass "Service selector app=amazon-web" || fail "Service selector app is '$sel' (expected amazon-web — it must match the Pods' labels exactly)"

eps=$(kubectl -n amazon get endpoints amazon-web -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)
n=$(echo $eps | wc -w)
[[ "$n" == "2" ]] && pass "Endpoints list both Pod IPs" || fail "Endpoints has $n address(es), expected 2 — 'kubectl -n amazon get endpoints amazon-web' is the first thing to look at"

ip=$(svcip amazon amazon-web || true)
[[ -n "$ip" ]] && pass "Service has a ClusterIP ($ip)" || { fail "Service amazon-web has no ClusterIP"; exit 1; }
reach amazon probe "http://$ip:80" && pass "the probe Pod can fetch the Service" || fail "http://$ip:80 is not reachable from Pod probe in amazon"
body=$(sample amazon probe "http://$ip:80" 3 || true)
echo "$body" | grep -q "amazon-web" && pass "the Service answers from the amazon-web Pods" || fail "the Service answered with '$(echo "$body" | head -1)' (expected 'amazon-web')"

exit ${FAILED}
