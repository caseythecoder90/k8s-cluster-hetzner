#!/bin/bash
# Score yourself.  ./verify-all.sh   or   ./verify-all.sh q02 q08
cd "$(dirname "$0")"
QS=${@:-$(ls -d q[0-9]* p[0-9]* 2>/dev/null | sort)}
pass=0; total=0
for q in $QS; do
  [[ -x "$q/verify.sh" ]] || continue
  total=$((total+1))
  if ./"$q"/verify.sh; then pass=$((pass+1)); fi
done
echo
echo "==== $pass / $total scenarios fully correct ===="
