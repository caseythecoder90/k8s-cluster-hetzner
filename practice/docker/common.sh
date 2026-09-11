#!/bin/bash
# Shared helpers for the Docker drill set.
#
# This set runs against YOUR LOCAL Docker daemon (Docker Desktop) — not the
# Hetzner lab, which runs containerd with no Docker daemon at all.
#
# Usage in a scenario script:  source "$(dirname "$0")/../common.sh"
set -euo pipefail

SET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$SET_DIR/work"
REG_PORT="${REG_PORT:-5000}"
REG="localhost:$REG_PORT"
mkdir -p "$WORK"

# Everything this set creates is named ckad-* (or localhost:PORT/ckad-*), so
# cleanup.sh can never touch your own dev containers and images.

docker version --format '{{.Server.Version}}' >/dev/null 2>&1 || {
  echo "REFUSING: no Docker daemon reachable. Start Docker Desktop, then re-run." >&2
  exit 1
}

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }

# qdir q03  — make (and echo) this question's working directory
qdir() { mkdir -p "$WORK/$1"; echo "$WORK/$1"; }

# crm <name...>   — remove containers if present, quietly
crm() { for c in "$@"; do docker rm -f "$c" >/dev/null 2>&1 || true; done; }
# irm <image...>  — remove images if present, quietly
irm() { for i in "$@"; do docker rmi -f "$i" >/dev/null 2>&1 || true; done; }

# pullbase <image...> — pull once, quietly, so a question isn't timing a download
pullbase() { for i in "$@"; do docker image inspect "$i" >/dev/null 2>&1 || docker pull -q "$i" >/dev/null; done; }

running()   { [[ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null || true)" == "true" ]]; }
exists()    { docker inspect "$1" >/dev/null 2>&1; }
imgexists() { docker image inspect "$1" >/dev/null 2>&1; }
ins()       { docker inspect -f "$2" "$1" 2>/dev/null || true; }

# hostport <container> <container-port>  — the host port it is published on
hostport() { docker port "$1" "$2" 2>/dev/null | head -1 | sed 's/.*://' | tr -d '\r'; }

# imgsize <ref> — image size in bytes
imgsize() { docker image inspect -f '{{.Size}}' "$1" 2>/dev/null || echo 0; }

# answer <file> <n>  — line n of an answer file, whitespace and CR stripped
answer() { sed -n "${2}p" "$1" 2>/dev/null | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

# squash <file> — whole file, lowercased, all whitespace removed (for loose compares)
squash() { tr -d '\r' < "$1" 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'; }

# lineno <file> <regex> — line number of the first match, or 0
lineno() { grep -nEi -m1 "$2" "$1" 2>/dev/null | cut -d: -f1 || true; }
