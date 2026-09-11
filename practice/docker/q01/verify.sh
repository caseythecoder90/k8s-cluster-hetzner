#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q01:"
d="$WORK/q01"

grep -qEi '^[[:space:]]*ENV[[:space:]]+MOON_CIPHER_ID' "$d/Dockerfile" 2>/dev/null \
  && pass "Dockerfile sets MOON_CIPHER_ID with ENV" \
  || fail "no ENV MOON_CIPHER_ID line in work/q01/Dockerfile (a run-time -e does not count)"

imgexists "$REG/moon-cipher:v1" && pass "image $REG/moon-cipher:v1 built" \
  || { fail "image $REG/moon-cipher:v1 not found"; exit 1; }

env=$(ins "$REG/moon-cipher:v1" '{{range .Config.Env}}{{println .}}{{end}}')
echo "$env" | grep -q '^MOON_CIPHER_ID=8f4c2a$' && pass "MOON_CIPHER_ID=8f4c2a baked into the image" \
  || fail "the image's env has no MOON_CIPHER_ID=8f4c2a (got: $(echo "$env" | grep MOON || echo none))"

imgexists ckad-moon:latest && pass "second tag ckad-moon:latest exists" \
  || fail "ckad-moon:latest not found — docker tag <src> ckad-moon:latest"

a=$(ins "$REG/moon-cipher:v1" '{{.Id}}'); b=$(ins ckad-moon:latest '{{.Id}}')
[[ -n "$a" && "$a" == "$b" ]] && pass "both tags point at the same image ID" \
  || fail "the two tags are different images — you rebuilt instead of tagging"

out=$(docker run --rm ckad-moon:latest 2>&1 | tr -d '\r' || true)
echo "$out" | grep -q 'id=8f4c2a' && pass "container prints id=8f4c2a" || fail "container printed: $out"

exit ${FAILED}
