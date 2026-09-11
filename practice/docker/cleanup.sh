#!/bin/bash
# Remove everything this set created, and nothing else.
#
# It matches only ckad-* names. It deliberately does NOT run
# `docker system prune` — on your laptop that would also delete images and
# volumes belonging to your own projects. (On the exam host, prune away.)
source "$(dirname "$0")/common.sh"

cs=$(docker ps -aq --filter "name=^ckad-" || true)
if [[ -n "$cs" ]]; then
  echo "removing containers:"; docker ps -a --filter "name=^ckad-" --format '  {{.Names}} ({{.Status}})'
  docker rm -f $cs >/dev/null
fi

is=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E '^(localhost:[0-9]+/)?ckad-|^localhost:[0-9]+/moon-cipher' || true)
if [[ -n "$is" ]]; then
  echo "removing images:"; echo "$is" | sed 's/^/  /'
  docker rmi -f $is >/dev/null 2>&1 || true
fi

if [[ -d "$WORK" ]]; then
  echo "removing $WORK"
  rm -rf "$WORK"
fi
echo "done — your own containers and images were not touched."
