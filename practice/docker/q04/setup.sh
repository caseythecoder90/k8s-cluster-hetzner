#!/bin/bash
source "$(dirname "$0")/../common.sh"
d="$WORK/q04"; rm -rf "$d"; mkdir -p "$d"
crm ckad-q04c
irm ckad-q04:v1 ckad-q04-flat:v1
pullbase alpine:3.20

cat > "$d/Dockerfile" <<'EOF'
FROM alpine:3.20
ENV HYDRA_STAGE=archive
RUN echo "hydra payload" > /payload.txt
CMD ["cat", "/payload.txt"]
EOF

docker build -q -t ckad-q04:v1 "$d" >/dev/null
echo "  q04 ready: image ckad-q04:v1 built, $d empty"
