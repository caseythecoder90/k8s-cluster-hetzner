#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q16:"
echo "  (no ingress controller in this lab — the Ingress object is checked structurally, nothing is fetched through it)"

$SSH_CP "test -f /course6/16/elbe-routes.yaml" && pass "manifest saved at /course6/16/elbe-routes.yaml" || fail "/course6/16/elbe-routes.yaml is missing"

kubectl -n elbe get ingress elbe-routes >/dev/null 2>&1 \
  && pass "Ingress elbe-routes exists in elbe" \
  || { fail "no Ingress named elbe-routes in Namespace elbe"; exit 1; }

# One deterministic line per path: host|path|pathType|service|port
TPL='{{range .spec.rules}}{{$h := .host}}{{range .http.paths}}{{$h}}|{{.path}}|{{.pathType}}|{{.backend.service.name}}|{{.backend.service.port.number}}{{"\n"}}{{end}}{{end}}'
routes=$(kubectl -n elbe get ingress elbe-routes -o go-template="$TPL" 2>/dev/null | grep -v '^[[:space:]]*$' || true)
echo "  routes found:"
printf '    %s\n' $routes

nrules=$(kubectl -n elbe get ingress elbe-routes -o jsonpath='{.spec.rules[*].host}' 2>/dev/null | wc -w | tr -d ' ')
npaths=$(printf '%s\n' "$routes" | grep -c . || true)
[[ "$nrules" == "2" ]] && pass "2 rules (one per host)" || fail "$nrules rules with a host (expected 2: shop.elbe.example.com and api.elbe.example.com)"
[[ "$npaths" == "3" ]] && pass "3 paths in total" || fail "$npaths paths in total (expected 3)"

want() {
  printf '%s\n' "$routes" | grep -qxF "$1" && pass "route $1" || fail "missing route '$1' — got the list printed above"
}
want 'shop.elbe.example.com|/|Prefix|site|80'
want 'shop.elbe.example.com|/api|Prefix|api|8080'
want 'api.elbe.example.com|/|Prefix|api|8080'

# A named port (or a missing host) leaves the field unset, which go-template
# renders as "<no value>" — call that out rather than letting it read as a
# mysterious missing route.
printf '%s\n' "$routes" | grep -qE '(\|$|<no value>)' \
  && fail "a field is unset in the routes above — '<no value>' in the port column means you used backend.service.port.name; the task asks for the port by number" \
  || pass "every route has a host, path, pathType and a numeric backend port"

# The Ingress must point at Services that really exist, with those ports.
[[ "$(kubectl -n elbe get svc site -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)" == "80" ]] && pass "Service site still publishes :80" || fail "Service site is missing or no longer on port 80"
[[ "$(kubectl -n elbe get svc api  -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)" == "8080" ]] && pass "Service api still publishes :8080" || fail "Service api is missing or no longer on port 8080 — the Ingress backend port must be the SERVICE port, not the container's 80"
[[ -n "$(kubectl -n elbe get endpoints site -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)" ]] && pass "Service site has Endpoints" || fail "Service site has no Endpoints"
[[ -n "$(kubectl -n elbe get endpoints api  -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)" ]] && pass "Service api has Endpoints"  || fail "Service api has no Endpoints"

exit ${FAILED}
