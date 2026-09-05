#!/bin/bash
# Tear down the CKAD practice lab — every Terraform workspace, verified against
# the Hetzner API afterwards, with the leftovers that lie to you next session
# (stale kubeconfig, recycled-IP host keys) cleaned up too.
#
#   ./practice/scripts/lab-down.sh            # destroy every workspace (terraform prompts)
#   ./practice/scripts/lab-down.sh --yes      # ...without the prompts
#   ./practice/scripts/lab-down.sh --status   # report only, destroy nothing
#
# Why this exists rather than a bare `terraform destroy`: that command only
# covers the workspace you happen to have selected, tells you nothing about the
# workspaces you forgot, and reports success from state alone — it cannot see a
# resource that drifted out of state. This script asks Hetzner what is actually
# still running and fails loudly if anything survived.
#
# SAFETY: this script never deletes anything through the Hetzner API. Terraform
# is the only thing that destroys; the API is read-only here, used to verify and
# to report. It also only ever runs Terraform in practice/terraform, so prod
# (separate state, separate directory, `prod-` names) is out of reach by
# construction.
#
# Requires: terraform, curl, python3, and HCLOUD_TOKEN — the same token
# Terraform already needs.
set -euo pipefail

# common.sh exports TF_WORKSPACE, and a set TF_WORKSPACE makes Terraform refuse
# any workspace command that disagrees with it. Drop it and address each
# workspace explicitly per-invocation instead.
unset TF_WORKSPACE

PRACTICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$PRACTICE_DIR/terraform"

# Every lab resource is named from cluster_name (practice/terraform/main.tf):
# lab-cp-1, lab-worker-1, lab-net, lab-fw, and lab-<workspace>-* for a second
# lab. Prod is `prod-`, so this prefix cannot match it.
LAB_PREFIX="${LAB_PREFIX:-lab-}"

# Name prefixes this repo's two Terraform configs own. A running server whose
# name matches neither is unmanaged: nothing here can destroy it, and it bills
# until you delete it by hand. The Aug 2026 invoice was 40% exactly that.
MANAGED_PREFIXES="${MANAGED_PREFIXES:-lab- prod-}"

# practice/README.md says "~2 cents/hour for the pair", and invoice 082001141468
# confirms it: CX23 at $0.0104/server-hour, so $0.0208 for the two nodes.
LAB_HOURLY_CENTS="${LAB_HOURLY_CENTS:-2}"
LAB_MAX_HOURS="${LAB_MAX_HOURS:-8}"

STATUS_ONLY=0
APPROVE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --status)     STATUS_ONLY=1 ;;
    --yes|-y)     APPROVE="-auto-approve" ;;
    --hours)      LAB_MAX_HOURS="${2:?--hours needs a number}"; shift ;;
    -h|--help)    sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 0 ;;
    *)            echo "unknown argument: $1 (try --help)" >&2; exit 1 ;;
  esac
  shift
done

[[ "$LAB_PREFIX" == prod* ]] && { echo "REFUSING: LAB_PREFIX '$LAB_PREFIX' would match prod resources" >&2; exit 1; }
[[ "$STATUS_ONLY" == 1 || -d "$TF_DIR" ]] || { echo "REFUSING: $TF_DIR does not exist" >&2; exit 1; }
: "${HCLOUD_TOKEN:?HCLOUD_TOKEN is not set — export it (the same token Terraform uses)}"
# --status only reads the API, so it stays usable from a machine that has no
# Terraform and no state — the check you want to be able to run from anywhere.
REQUIRED="curl python3"
[[ "$STATUS_ONLY" == 1 ]] || REQUIRED="terraform $REQUIRED"
for t in $REQUIRED; do
  command -v "$t" >/dev/null || { echo "missing required tool: $t" >&2; exit 1; }
done

api() { curl -fsS -H "Authorization: Bearer $HCLOUD_TOKEN" "https://api.hetzner.cloud/v1/$1"; }

# Emit one TSV row per live lab resource: KIND, name, age in hours, public IPv4.
PARSE_PY='
import sys, json, datetime
kind, key, prefix = sys.argv[1], sys.argv[2], sys.argv[3]
now = datetime.datetime.now(datetime.timezone.utc)
for it in json.load(sys.stdin).get(key, []):
    name = it.get("name") or ""
    if not name.startswith(prefix):
        continue
    hours = ""
    created = it.get("created")
    if created:
        t = datetime.datetime.fromisoformat(created.replace("Z", "+00:00"))
        hours = "%.1f" % ((now - t).total_seconds() / 3600.0)
    # servers carry the address under public_net; a Primary IP has it top-level
    ip = ((it.get("public_net") or {}).get("ipv4") or {}).get("ip") or it.get("ip") or ""
    print("\t".join([kind, name, hours, ip]))
'

lab_rows() {
  api "servers?per_page=50"    | python3 -c "$PARSE_PY" SERVER   servers     "$LAB_PREFIX"
  api "networks?per_page=50"   | python3 -c "$PARSE_PY" NETWORK  networks    "$LAB_PREFIX"
  api "firewalls?per_page=50"  | python3 -c "$PARSE_PY" FIREWALL firewalls   "$LAB_PREFIX"
  api "primary_ips?per_page=50"| python3 -c "$PARSE_PY" PRIMARY_IP primary_ips "$LAB_PREFIX"
}

# Resources nothing in this repo creates, so Terraform can never clean them up:
# they bill until you delete them by hand. An unassigned Primary IP and a
# detached Volume both cost money while attached to nothing.
strays() {
  api "servers?per_page=50" | python3 -c '
import sys, json, datetime
managed = sys.argv[1].split()
now = datetime.datetime.now(datetime.timezone.utc)
for s in json.load(sys.stdin).get("servers", []):
    name = s.get("name") or ""
    if any(name.startswith(p) for p in managed):
        continue
    hours = 0.0
    if s.get("created"):
        t = datetime.datetime.fromisoformat(s["created"].replace("Z", "+00:00"))
        hours = (now - t).total_seconds() / 3600.0
    print("  server    %-28s %-8s up %5.0f h  %s" % (
        name, (s.get("server_type") or {}).get("name", "?"), hours,
        ((s.get("public_net") or {}).get("ipv4") or {}).get("ip") or ""))' "$MANAGED_PREFIXES"
  api "volumes?per_page=50" | python3 -c '
import sys, json
for v in json.load(sys.stdin).get("volumes", []):
    where = "attached to server %s" % v["server"] if v.get("server") else "DETACHED"
    print("  volume    %-28s %4d GB  %s" % (v.get("name",""), v.get("size",0), where))'
  api "images?type=snapshot&per_page=50" | python3 -c '
import sys, json
for i in json.load(sys.stdin).get("images", []):
    print("  snapshot  %-28s %4.1f GB  %s" % (i.get("description") or i.get("name") or i["id"], i.get("image_size") or 0, i.get("created","")))'
  api "primary_ips?per_page=50" | python3 -c '
import sys, json
for p in json.load(sys.stdin).get("primary_ips", []):
    if not p.get("assignee_id"):
        print("  primary_ip %-27s %s  UNASSIGNED (still billing)" % (p.get("name",""), p.get("ip","")))'
}

# Print the strays block, or say so plainly when there are none — an empty
# heading reads like the check silently failed.
strays_report() {
  local out; out="$(strays)"
  echo "Unmanaged in THIS Hetzner project (not created by either Terraform config,"
  echo "so nothing here can destroy them — they bill until deleted by hand):"
  [[ -n "$out" ]] && printf '%s\n' "$out" || echo "  (none)"
}

report() {
  local rows="$1" oldest
  if [[ -z "$rows" ]]; then
    echo "No '$LAB_PREFIX' resources are running in this Hetzner project."
    return 1
  fi
  echo "Live lab resources:"
  printf '%s\n' "$rows" | awk -F'\t' '{printf "  %-11s %-24s %6s h  %s\n", $1, $2, ($3==""?"-":$3), $4}'
  # Servers only: networks and firewalls cost nothing, and the pair runs
  # concurrently, so it is the longest-lived *server*, not the sum of the rows.
  # LAB_HOURLY_CENTS is already the rate for both nodes together.
  oldest=$(printf '%s\n' "$rows" | awk -F'\t' '$1=="SERVER" && $3!=""{print $3}' | sort -rn | head -1)
  [[ -n "$oldest" ]] || return 0
  printf 'Up for %.1f h — roughly $%.2f so far at ~%s cents/hour for the pair.\n' \
    "$oldest" "$(python3 -c "print($oldest*$LAB_HOURLY_CENTS/100)")" "$LAB_HOURLY_CENTS"
  awk -v h="$oldest" -v m="$LAB_MAX_HOURS" 'BEGIN{ if (h+0 > m+0)
    printf "\n  !! This lab has been up %.1f h, past the %s h session limit.\n     A session should cost cents; a forgotten weekend is the bill you noticed.\n", h, m }'
  return 0
}

ROWS="$(lab_rows)"

if [[ "$STATUS_ONLY" == 1 ]]; then
  # Always report strays, lab up or down: an unmanaged server bills exactly the
  # same either way, and a torn-down lab is the likeliest moment to be looking.
  # Exit 2 = lab is up, so this is usable from a shell prompt or a cron nag.
  if report "$ROWS"; then LAB_UP=2; else LAB_UP=0; fi
  echo
  strays_report
  exit "$LAB_UP"
fi

report "$ROWS" || { echo "Nothing to destroy."; exit 0; }
echo

# Keep the IPs before they are gone: Hetzner recycles them, so their old host
# keys have to come out of known_hosts or the next lab trips a key mismatch.
LAB_IPS="$(printf '%s\n' "$ROWS" | awk -F'\t' '$1=="SERVER" && $4!=""{print $4}')"

WORKSPACES="$(cd "$TF_DIR" && terraform workspace list | sed 's/^[* ]*//' | grep -v '^$')"
echo "Destroying workspaces: $(echo "$WORKSPACES" | tr '\n' ' ')"
echo
for ws in $WORKSPACES; do
  echo "=== workspace: $ws ==="
  # A workspace that was never applied has an empty state; destroy is a no-op
  # there, so an error must not abort the workspaces after it.
  ( cd "$TF_DIR" && TF_WORKSPACE="$ws" terraform destroy $APPROVE ) || {
    echo "  ! destroy failed for workspace '$ws' — continuing; the check below is authoritative" >&2
  }
  # A kubeconfig outliving its cluster is the dangerous leftover: it still holds
  # a lab context, so a later `kubectl` can look healthy while pointing at an IP
  # Hetzner has since handed to someone else.
  kc="$PRACTICE_DIR/ansible/kubeconfig/admin.conf"
  [[ "$ws" != "default" ]] && kc="$PRACTICE_DIR/ansible/kubeconfig/admin-$ws.conf"
  [[ -f "$kc" ]] && { rm -f "$kc"; echo "  removed stale kubeconfig $(basename "$kc")"; }
  echo
done

for ip in $LAB_IPS; do
  ssh-keygen -R "$ip" -f "$HOME/.ssh/known_hosts_lab" >/dev/null 2>&1 || true
  ssh-keygen -R "$ip"                                  >/dev/null 2>&1 || true
done
[[ -n "$LAB_IPS" ]] && echo "Cleared host keys for: $(echo "$LAB_IPS" | tr '\n' ' ')"

# The point of the whole script: confirm with Hetzner, not with Terraform state.
echo
echo "Verifying against the Hetzner API..."
LEFT="$(lab_rows)"
if [[ -n "$LEFT" ]]; then
  echo
  echo "  X TEARDOWN INCOMPLETE — these are still running and still billing:" >&2
  printf '%s\n' "$LEFT" | awk -F'\t' '{printf "      %-11s %-24s\n", $1, $2}' >&2
  echo "    Delete them in the Hetzner Console, or re-run after fixing the failed workspace." >&2
  exit 1
fi

echo "  OK - no '$LAB_PREFIX' resources remain. The lab is fully torn down."
echo
strays_report
