#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q04:"
d="$WORK/q04"

[[ -s "$d/img.tar" ]] && pass "img.tar exists" || fail "work/q04/img.tar missing or empty (docker save -o img.tar ckad-q04:v1)"
[[ -s "$d/ctr.tar" ]] && pass "ctr.tar exists" || fail "work/q04/ctr.tar missing or empty (docker export -o ctr.tar ckad-q04c)"

if [[ -s "$d/img.tar" ]]; then
  tar -tf "$d/img.tar" 2>/dev/null | grep -qE 'manifest.json|blobs/' \
    && pass "img.tar is an image archive (has a manifest)" \
    || fail "img.tar has no image manifest — that looks like an export, not a save"
fi

imgexists ckad-q04:v1 && pass "ckad-q04:v1 present again after load" \
  || fail "ckad-q04:v1 is not in the image store — load it back from img.tar"

imgexists ckad-q04-flat:v1 && pass "ckad-q04-flat:v1 imported" \
  || { fail "ckad-q04-flat:v1 not found (docker import ctr.tar ckad-q04-flat:v1)"; }

if imgexists ckad-q04-flat:v1; then
  cmd=$(ins ckad-q04-flat:v1 '{{json .Config.Cmd}}')
  [[ "$cmd" == "null" || "$cmd" == "[]" ]] && pass "the imported image has no CMD — the point of the question" \
    || fail "the imported image has CMD $cmd; expected none (did you re-tag the saved image instead of importing?)"
fi

got=$(squash "$d/answer.txt" 2>/dev/null || true)
[[ "$got" == "save" ]] && pass "answer.txt: save" || fail "answer.txt says '$got' (expected 'save')"

exit ${FAILED}
