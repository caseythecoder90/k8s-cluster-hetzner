#!/bin/bash
source "$(dirname "$0")/../common.sh"
FAILED=0
echo "q10:"
d="$WORK/q10"
f="$d/pod.yaml"

[[ -f "$f" ]] || { fail "work/q10/pod.yaml missing"; exit 1; }
y=$(tr -d '\r' < "$f")

echo "$y" | grep -qE '^[[:space:]]*kind:[[:space:]]*Pod' && pass "kind: Pod" || fail "not a Pod manifest"
echo "$y" | grep -qE '^[[:space:]]*name:[[:space:]]*ckad-q10' && pass "Pod named ckad-q10" || fail "Pod name is not ckad-q10"
echo "$y" | grep -qE '^[[:space:]]*-?[[:space:]]*name:[[:space:]]*app' && pass "container named app" || fail "no container named app"
echo "$y" | grep -qE 'image:[[:space:]]*ckad-q10:v1' && pass "image ckad-q10:v1" || fail "image is not ckad-q10:v1"

echo "$y" | grep -qE '^[[:space:]]*command:' \
  && fail "there is a 'command:' field — it would override the image's ENTRYPOINT, which the task said to keep" \
  || pass "no command: field, so the image's ENTRYPOINT stands"

echo "$y" | grep -qE '^[[:space:]]*args:' && pass "args: is set" || fail "no args: field"
echo "$y" | grep -q -- '--mode=fast' && pass "args carry --mode=fast" || fail "--mode=fast not found in the manifest"
echo "$y" | grep -q -- '--mode=slow' && fail "--mode=slow is still in the manifest" || pass "the image's default argument is gone"

echo "$y" | grep -qE 'runAsUser:[[:space:]]*1001' && pass "securityContext.runAsUser: 1001" || fail "runAsUser: 1001 not set"
echo "$y" | grep -qE 'containerPort:[[:space:]]*8080' && pass "containerPort: 8080" || fail "containerPort 8080 not declared (the Dockerfile EXPOSEs it)"

af="$d/answer.txt"
if [[ -f "$af" ]]; then
  l1=$(answer "$af" 1 | tr '[:lower:]' '[:upper:]')
  l2=$(answer "$af" 2 | tr '[:lower:]' '[:upper:]')
  [[ "$l1" == *ENTRYPOINT* ]] && pass "command: overrides ENTRYPOINT" || fail "line 1 of answer.txt should name ENTRYPOINT (got '$l1')"
  [[ "$l2" == *CMD* && "$l2" != *ENTRYPOINT* ]] && pass "args: overrides CMD" || fail "line 2 of answer.txt should name CMD (got '$l2')"
else
  fail "work/q10/answer.txt missing"
fi

exit ${FAILED}
