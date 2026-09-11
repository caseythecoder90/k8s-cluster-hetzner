#!/bin/bash
source "$(dirname "$0")/../common.sh"
d="$WORK/q07"; rm -rf "$d"; mkdir -p "$d"
irm ckad-q07:v1
pullbase alpine:3.20

cat > "$d/app.sh" <<'EOF'
#!/bin/sh
echo "app v1"
EOF
chmod +x "$d/app.sh" 2>/dev/null || true

cat > "$d/Dockerfile" <<'EOF'
FROM alpine:3.20
WORKDIR /app
COPY . /app
RUN apk add --no-cache curl
CMD ["/app/app.sh"]
EOF
echo "  q07 ready: $d"
