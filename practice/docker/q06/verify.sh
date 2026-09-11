#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q06:"
d="$WORK/q06"

imgexists ckad-q06:fat  && pass "ckad-q06:fat built"  || fail "ckad-q06:fat not found (build the original Dockerfile first)"
imgexists ckad-q06:slim && pass "ckad-q06:slim built" || { fail "ckad-q06:slim not found"; exit 1; }

grep -qiE '^[[:space:]]*FROM .* AS ' "$d/Dockerfile" && pass "Dockerfile names a build stage (FROM ... AS ...)" \
  || fail "no 'FROM ... AS <name>' in work/q06/Dockerfile — that is what makes it multi-stage"
grep -qiE 'COPY[[:space:]]+--from=' "$d/Dockerfile" && pass "final stage copies from the build stage" \
  || fail "no 'COPY --from=' in work/q06/Dockerfile"

# Note: `docker images` prints the uncompressed size while `docker image
# inspect .Size` can report the compressed one, so the two disagree. The
# threshold is generous enough to be right under either.
sz=$(imgsize ckad-q06:slim)
human=$(docker images ckad-q06:slim --format '{{.Size}}' 2>/dev/null | head -1 || true)
[[ "$sz" -gt 0 && "$sz" -lt 20000000 ]] && pass "ckad-q06:slim is $human — the toolchain is gone" \
  || fail "ckad-q06:slim is $human — the compiler is still in the final image"

out=$(docker run --rm ckad-q06:slim 2>&1 | tr -d '\r' || true)
echo "$out" | grep -q 'hydra v2 ok' && pass "slim image still prints 'hydra v2 ok'" || fail "slim image printed: $out"

# `sh`, not `/bin/sh`: Git Bash rewrites a leading-slash argument into a
# Windows path before Docker sees it. See README.
gcc=$(docker run --rm --entrypoint sh ckad-q06:slim -c 'command -v gcc || true' 2>/dev/null | tr -d '\r' || true)
[[ -z "$gcc" ]] && pass "no compiler in the final image" || fail "gcc is still present at $gcc"

[[ -s "$d/sizes.txt" ]] && pass "sizes.txt written" || fail "work/q06/sizes.txt missing or empty"

exit ${FAILED}
