#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q03:"

jp() { kubectl -n ganges get svc ganges-web -o jsonpath="$1" 2>/dev/null || true; }

$SSH_CP "test -s /course6/3/service.yaml" && pass "/course6/3/service.yaml saved" || fail "/course6/3/service.yaml is missing or empty — the task asks for the manifest on disk"

[[ -n "$(jp '{.metadata.name}')" ]] && pass "Service ganges-web exists" || { fail "Service ganges-web not found in Namespace ganges"; exit 1; }

st=$(jp '{.spec.type}')
[[ "$st" == "ClusterIP" ]] && pass "type ClusterIP" || fail "Service type is '$st' (expected ClusterIP)"
sel=$(jp '{.spec.selector.app}')
[[ "$sel" == "ganges-web" ]] && pass "selector app=ganges-web" || fail "Service selector app is '$sel' (expected ganges-web)"

nports=$(jp '{.spec.ports[*].port}' | wc -w)
[[ "$nports" == "2" ]] && pass "the Service publishes 2 ports" || fail "the Service has $nports port(s), expected 2"

names=$(jp '{.spec.ports[*].name}')
echo " $names " | grep -q " http "    && pass "a port named 'http'"    || fail "no Service port named 'http' (names found: '$names') — every port of a multi-port Service needs a unique name"
echo " $names " | grep -q " metrics " && pass "a port named 'metrics'" || fail "no Service port named 'metrics' (names found: '$names')"

hp=$(jp '{.spec.ports[?(@.name=="http")].port}')
ht=$(jp '{.spec.ports[?(@.name=="http")].targetPort}')
mp=$(jp '{.spec.ports[?(@.name=="metrics")].port}')
mt=$(jp '{.spec.ports[?(@.name=="metrics")].targetPort}')
[[ "$hp" == "80" ]]      && pass "http port 80"                  || fail "the 'http' Service port is '$hp' (expected 80)"
[[ "$ht" == "http" ]]    && pass "http targetPort is the NAME 'http'" || fail "the 'http' targetPort is '$ht' — the task requires the container port's name, not the number 80"
[[ "$mp" == "9113" ]]    && pass "metrics port 9113"             || fail "the 'metrics' Service port is '$mp' (expected 9113)"
[[ "$mt" == "9113" || "$mt" == "metrics" ]] && pass "metrics targetPort resolves to container port 9113" || fail "the 'metrics' targetPort is '$mt' (expected 9113)"

eps=$(kubectl -n ganges get endpoints ganges-web -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)
[[ "$(echo $eps | wc -w)" == "2" ]] && pass "Endpoints list both Pod IPs" || fail "Endpoints has $(echo $eps | wc -w) address(es), expected 2"
epp=$(kubectl -n ganges get endpoints ganges-web -o jsonpath='{.subsets[0].ports[*].port}' 2>/dev/null || true)
echo " $epp " | grep -q " 80 "   && pass "Endpoints resolved the named port to 80" || fail "Endpoints ports are '$epp' — the name 'http' did not resolve to container port 80"
echo " $epp " | grep -q " 9113 " && pass "Endpoints carry port 9113"               || fail "Endpoints ports are '$epp' — 9113 is missing"

ip=$(svcip ganges ganges-web || true)
[[ -n "$ip" ]] && pass "Service has a ClusterIP ($ip)" || { fail "Service has no ClusterIP"; exit 1; }
b1=$(sample ganges probe "http://$ip:80" 2 || true)
b2=$(sample ganges probe "http://$ip:9113" 2 || true)
echo "$b1" | grep -q "ganges-web"     && pass ":80 serves the app page"      || fail "http://$ip:80 returned '$(echo "$b1" | head -1)' (expected ganges-web)"
echo "$b2" | grep -q "ganges-metrics" && pass ":9113 serves the metrics page" || fail "http://$ip:9113 returned '$(echo "$b2" | head -1)' (expected ganges-metrics)"

exit ${FAILED}
