#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q03:"
d="$WORK/q03"

running ckad-web && pass "container ckad-web is running" || { fail "no running container named ckad-web"; exit 1; }

img=$(ins ckad-web '{{.Config.Image}}')
[[ "$img" == nginx:1-alpine ]] && pass "built from nginx:1-alpine" || fail "container image is '$img'"

hp=$(hostport ckad-web 80)
[[ "$hp" == "18080" ]] && pass "container port 80 published on host 18080" \
  || fail "port 80 is published on host port '$hp' (expected 18080) — -p HOST:CONTAINER"

ins ckad-web '{{range .Config.Env}}{{println .}}{{end}}' | grep -q '^APP_ENV=exam$' \
  && pass "APP_ENV=exam set on the container" || fail "APP_ENV=exam not set (docker run -e APP_ENV=exam)"

if [[ -s "$d/logs.txt" ]]; then
  grep -qE 'GET |HTTP/1' "$d/logs.txt" && pass "logs.txt holds a request log line" \
    || fail "logs.txt exists but has no request in it — hit the server once, then re-run docker logs"
else
  fail "work/q03/logs.txt missing or empty"
fi

got=$(squash "$d/env.txt" 2>/dev/null || true)
[[ "$got" == "exam" ]] && pass "env.txt contains exam" || fail "env.txt contains '$got' (expected 'exam')"

exit ${FAILED}
