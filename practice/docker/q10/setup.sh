#!/bin/bash
source "$(dirname "$0")/../common.sh"
d="$WORK/q10"; rm -rf "$d"; mkdir -p "$d"

cat > "$d/Dockerfile" <<'EOF'
FROM alpine:3.20
ENV APP_HOME=/opt/app
EXPOSE 8080
USER 1001
ENTRYPOINT ["/opt/app/server"]
CMD ["--mode=slow"]
EOF
echo "  q10 ready: $d"
