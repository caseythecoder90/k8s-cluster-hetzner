#!/bin/bash
source "$(dirname "$0")/../common.sh"
d="$WORK/q01"; rm -rf "$d"; mkdir -p "$d"
crm ckad-q01
irm ckad-moon:latest "$REG/moon-cipher:v1"
pullbase alpine:3.20

cat > "$d/run.sh" <<'EOF'
#!/bin/sh
echo "moon-cipher reporting, id=${MOON_CIPHER_ID:-UNSET}"
EOF

cat > "$d/Dockerfile" <<'EOF'
FROM alpine:3.20
COPY run.sh /run.sh
RUN chmod +x /run.sh
CMD ["/run.sh"]
EOF
echo "  q01 ready: $d"
