#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q07:"
d="$WORK/q07"

imgexists ckad-q07:v1 && pass "image ckad-q07:v1 built" || fail "ckad-q07:v1 not found"

apk=$(lineno "$d/Dockerfile" 'RUN .*apk add')
cp=$(lineno "$d/Dockerfile" '^[[:space:]]*COPY')
if [[ -n "$apk" && -n "$cp" ]]; then
  [[ "$apk" -lt "$cp" ]] && pass "apk add (line $apk) comes before COPY (line $cp)" \
    || fail "COPY is on line $cp, before apk add on line $apk — the install still rebuilds on every source change"
else
  fail "could not find both an 'apk add' and a 'COPY' line in work/q07/Dockerfile"
fi

grep -qiE '^[[:space:]]*COPY[[:space:]]+\.[[:space:]]' "$d/Dockerfile" \
  && fail "still 'COPY . /app' — copy just app.sh so the log file and .git stay out of the cache key" \
  || pass "narrowed the COPY to the file it needs"

if [[ -s "$d/build2.log" ]]; then
  pass "build2.log written"
  grep -qiE 'cached|using cache' "$d/build2.log" \
    && pass "the second build reused a cached layer" \
    || fail "no CACHED / 'Using cache' line in build2.log — the whole thing rebuilt"
else
  fail "work/q07/build2.log missing or empty"
fi

exit ${FAILED}
