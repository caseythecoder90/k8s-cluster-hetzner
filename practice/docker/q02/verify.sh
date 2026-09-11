#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q02:"
d="$WORK/q02"

imgexists ckad-q02:v1 && pass "image ckad-q02:v1 built" || { fail "image ckad-q02:v1 not found"; exit 1; }

ep=$(ins ckad-q02:v1 '{{json .Config.Entrypoint}}')
[[ "$ep" == '["echo"]' ]] && pass "Dockerfile left alone (ENTRYPOINT still echo)" \
  || fail "the image's ENTRYPOINT is $ep — the task said not to edit the Dockerfile"

for spec in "a hello" "b goodbye" "c overridden"; do
  set -- $spec
  f="$d/$1.txt"
  if [[ ! -f "$f" ]]; then fail "work/q02/$1.txt missing"; continue; fi
  got=$(squash "$f")
  [[ "$got" == "$2" ]] && pass "$1.txt contains $2" || fail "$1.txt contains '$got' (expected '$2')"
done

exit ${FAILED}
