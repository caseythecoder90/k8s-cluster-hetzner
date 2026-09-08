#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q02:"

jp() { kubectl -n danube get svc danube-web -o jsonpath="$1" 2>/dev/null || true; }

$SSH_CP "test -s /course6/2/service.yaml" && pass "/course6/2/service.yaml saved" || fail "/course6/2/service.yaml is missing or empty — the task asks for the manifest on disk"

[[ -n "$(jp '{.metadata.name}')" ]] && pass "Service danube-web exists" || { fail "Service danube-web not found in Namespace danube"; exit 1; }

st=$(jp '{.spec.type}')
[[ "$st" == "NodePort" ]] && pass "type NodePort" || fail "Service type is '$st' (expected NodePort)"
sel=$(jp '{.spec.selector.app}')
[[ "$sel" == "danube-web" ]] && pass "selector app=danube-web" || fail "Service selector app is '$sel' (expected danube-web)"

np=$(jp '{.spec.ports[0].port}')
tp=$(jp '{.spec.ports[0].targetPort}')
nodep=$(jp '{.spec.ports[0].nodePort}')
[[ "$np" == "8080" ]]     && pass "port 8080 (the Service's own port)"        || fail "spec.ports[0].port is '$np' (expected 8080 — the port the ClusterIP answers on)"
[[ "$tp" == "80" ]]       && pass "targetPort 80 (the container's port)"      || fail "spec.ports[0].targetPort is '$tp' (expected 80 — the port nginx actually listens on)"
[[ "$nodep" == "30602" ]] && pass "nodePort 30602 (the port on every node)"   || fail "spec.ports[0].nodePort is '$nodep' (expected 30602 — an unset nodePort means the cluster picked one at random)"

eps=$(kubectl -n danube get endpoints danube-web -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || true)
[[ "$(echo $eps | wc -w)" == "2" ]] && pass "Endpoints list both Pod IPs" || fail "Endpoints has $(echo $eps | wc -w) address(es), expected 2 — check the selector"
epp=$(kubectl -n danube get endpoints danube-web -o jsonpath='{.subsets[0].ports[0].port}' 2>/dev/null || true)
[[ "$epp" == "80" ]] && pass "Endpoints deliver to Pod port 80" || fail "Endpoints port is '$epp' (expected 80) — targetPort is what lands here"

ip=$(svcip danube danube-web || true)
[[ -n "$ip" ]] && pass "Service has a ClusterIP ($ip)" || fail "Service has no ClusterIP"
reach danube probe "http://$ip:8080" && pass "in-cluster: http://<clusterIP>:8080 answers" || fail "http://$ip:8080 not reachable from Pod probe — port/targetPort are the wrong way round?"

$SSH_CP "curl -s -m 5 http://10.10.1.10:30602" | grep -q "danube-web" && pass "from the node: http://10.10.1.10:30602 answers" || fail "nothing served on 10.10.1.10:30602"

exit ${FAILED}
