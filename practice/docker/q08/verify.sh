#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q08:"
d="$WORK/q08"
f="$d/answers.txt"

[[ -f "$f" ]] || { fail "work/q08/answers.txt missing"; exit 1; }

strip() { echo "$1" | sed 's/^[0-9]*:[[:space:]]*//' | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

exp_port=$(ins nginx:1-alpine '{{range $p, $v := .Config.ExposedPorts}}{{$p}}{{end}}' | sed 's|/.*||')
exp_ep=$(ins   nginx:1-alpine '{{index .Config.Entrypoint 0}}')
exp_layers=$(ins nginx:1-alpine '{{len .RootFS.Layers}}')
exp_user=$(ins nginx:1-alpine '{{.Config.User}}'); [[ -z "$exp_user" ]] && exp_user=root

a1=$(strip "$(answer "$f" 1)")
a2=$(strip "$(answer "$f" 2)")
a3=$(strip "$(answer "$f" 3)")
a4=$(strip "$(answer "$f" 4)")

[[ "$a1" == "$exp_port" ]] && pass "1: exposed port $exp_port" || fail "1: got '$a1', expected '$exp_port'"

case "$a2" in
  *docker-entrypoint.sh*) pass "2: entrypoint $exp_ep" ;;
  *) fail "2: got '$a2', expected something naming '$exp_ep'" ;;
esac

[[ "$a3" == "$exp_layers" ]] && pass "3: $exp_layers layers" || fail "3: got '$a3', expected '$exp_layers' (docker inspect -f '{{len .RootFS.Layers}}')"

[[ "$(echo "$a4" | tr '[:upper:]' '[:lower:]')" == "$exp_user" ]] && pass "4: runs as $exp_user" \
  || fail "4: got '$a4', expected '$exp_user' (an empty .Config.User means root)"

exit ${FAILED}
