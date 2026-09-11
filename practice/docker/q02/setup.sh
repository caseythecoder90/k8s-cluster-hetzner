#!/bin/bash
source "$(dirname "$0")/../common.sh"
d="$WORK/q02"; rm -rf "$d"; mkdir -p "$d"
irm ckad-q02:v1
pullbase busybox:1

cat > "$d/Dockerfile" <<'EOF'
FROM busybox:1
ENTRYPOINT ["echo"]
CMD ["hello"]
EOF
echo "  q02 ready: $d"
