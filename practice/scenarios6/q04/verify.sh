#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q04:"

jp() { kubectl -n hudson get "$1" "$2" -o jsonpath="$3" 2>/dev/null || true; }

[[ -n "$(jp svc hudson-web '{.metadata.name}')" ]] && pass "Service hudson-web exists" || { fail "Service hudson-web not found in Namespace hudson"; exit 1; }

cp=$(jp deploy hudson-web '{.spec.template.spec.containers[0].ports[0].containerPort}')
[[ "$cp" == "80" ]] && pass "container still declares port 80" || fail "the container port is now '$cp' — the task says fix the Service, not the Deployment"
lbl=$(jp deploy hudson-web '{.spec.template.metadata.labels.app}')
[[ "$lbl" == "hudson-web" ]] && pass "Pod label app=hudson-web unchanged" || fail "the Pod template label app is now '$lbl' — the Deployment must not be touched"
rr=$(jp deploy hudson-web '{.status.readyReplicas}')
[[ "$rr" == "2" ]] && pass "both hudson-web Pods still Ready" || fail "hudson-web has '$rr' ready Pods (expected 2)"

st=$(jp svc hudson-web '{.spec.type}')
[[ "$st" == "ClusterIP" ]] && pass "Service is still ClusterIP" || fail "Service type is '$st' (expected ClusterIP)"
sel=$(jp svc hudson-web '{.spec.selector.app}')
[[ "$sel" == "hudson-web" ]] && pass "selector app=hudson-web (it was never the problem)" || fail "Service selector app is '$sel' (expected hudson-web)"
p=$(jp svc hudson-web '{.spec.ports[0].port}')
[[ "$p" == "80" ]] && pass "Service port still 80" || fail "Service port is '$p' (expected 80 — the task keeps the front door where it was)"
tp=$(jp svc hudson-web '{.spec.ports[0].targetPort}')
[[ "$tp" == "80" || "$tp" == "http" ]] && pass "targetPort now points at the container's real port" || fail "spec.ports[0].targetPort is '$tp' — nginx listens on 80, so nothing answers on '$tp'"

eps=$(kubectl -n hudson get endpoints hudson-web -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)
[[ "$(echo $eps | wc -w)" == "2" ]] && pass "Endpoints still list both Pod IPs" || fail "Endpoints has $(echo $eps | wc -w) address(es), expected 2"
epp=$(kubectl -n hudson get endpoints hudson-web -o jsonpath='{.subsets[0].ports[0].port}' 2>/dev/null || true)
[[ "$epp" == "80" ]] && pass "Endpoints now deliver to Pod port 80" || fail "Endpoints port is '$epp' (expected 80) — targetPort is the value that lands here"

ip=$(svcip hudson hudson-web || true)
[[ -n "$ip" ]] && pass "Service has a ClusterIP ($ip)" || { fail "Service has no ClusterIP"; exit 1; }
reach hudson probe "http://$ip:80" && pass "the probe Pod can fetch the Service" || fail "http://$ip:80 is still not reachable from Pod probe in hudson"
body=$(sample hudson probe "http://$ip:80" 3 || true)
echo "$body" | grep -q "hudson-web" && pass "the Service answers from the hudson-web Pods" || fail "the Service answered with '$(echo "$body" | head -1)' (expected 'hudson-web')"

exit ${FAILED}
