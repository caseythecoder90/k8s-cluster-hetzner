#!/bin/bash
source "$(dirname "$0")/../common.sh"
d="$WORK/q06"; rm -rf "$d"; mkdir -p "$d"
irm ckad-q06:fat ckad-q06:slim
pullbase alpine:3.20

cat > "$d/app.c" <<'EOF'
#include <stdio.h>
int main(void) { printf("hydra v2 ok\n"); return 0; }
EOF

cat > "$d/Dockerfile" <<'EOF'
FROM alpine:3.20
RUN apk add --no-cache gcc musl-dev
WORKDIR /src
COPY app.c .
RUN gcc -static -o /usr/local/bin/app app.c
CMD ["app"]
EOF
echo "  q06 ready: $d  (first build downloads a compiler, ~1 min)"
