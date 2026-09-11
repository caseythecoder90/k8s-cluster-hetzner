#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q05:"
ref="$REG/ckad-hydra:v2"

running ckad-registry && pass "registry container is up on $REG" \
  || { fail "the ckad-registry container is not running — re-run ./setup-all.sh q05"; exit 1; }

if command -v curl >/dev/null 2>&1; then
  cat=$(curl -s --max-time 5 "http://$REG/v2/_catalog" 2>/dev/null || true)
  echo "$cat" | grep -q 'ckad-hydra' && pass "registry catalog lists ckad-hydra" \
    || fail "the registry has no ckad-hydra repository — the push did not land (catalog: $cat)"
fi

imgexists "$ref" && pass "$ref present locally" \
  || { fail "$ref not in the local image store — pull it back"; exit 1; }

dg=$(ins "$ref" '{{json .RepoDigests}}')
[[ "$dg" != "null" && "$dg" != "[]" ]] && pass "the local image carries a registry digest (it really came from the registry)" \
  || fail "no RepoDigests on the image — it was built locally, not pulled. Push it, rmi it, pull it."

out=$(docker run --rm "$ref" 2>&1 | tr -d '\r' || true)
echo "$out" | grep -q 'hydra v2' && pass "it runs and prints 'hydra v2'" || fail "running it printed: $out"

exit ${FAILED}
