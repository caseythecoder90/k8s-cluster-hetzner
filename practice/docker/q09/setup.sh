#!/bin/bash
source "$(dirname "$0")/../common.sh"
d="$WORK/q09"; rm -rf "$d"; mkdir -p "$d"
crm ckad-old ckad-dead ckad-new
irm ckad-junk:v1
pullbase alpine:3.20 nginx:1-alpine

docker build -q -t ckad-junk:v1 - >/dev/null <<'EOF'
FROM alpine:3.20
CMD ["sleep", "60"]
EOF

docker run -d --name ckad-old -p 18081:80 nginx:1-alpine >/dev/null
docker run --name ckad-dead ckad-junk:v1 /bin/true >/dev/null 2>&1 || true
echo "  q09 ready: something is squatting on host port 18081"
