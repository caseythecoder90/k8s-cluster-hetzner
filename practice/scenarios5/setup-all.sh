#!/bin/bash
# Build the starting state for every scenario (or the ones you name).
#   ./setup-all.sh            # all of them
#   ./setup-all.sh q02 q08    # just these
cd "$(dirname "$0")"
QS=${@:-$(ls -d q[0-9]* 2>/dev/null | sort)}
for q in $QS; do
  [[ -f "$q/setup.sh" ]] || continue
  echo "--- $q"
  bash "$q"/setup.sh || echo "  !! setup failed for $q"
done
echo
echo "All set. Read the tasks (cat TASKS-ALL.md), then solve on the control plane."
