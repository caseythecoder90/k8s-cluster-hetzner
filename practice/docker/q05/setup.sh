#!/bin/bash
source "$(dirname "$0")/../common.sh"
d="$WORK/q05"; rm -rf "$d"; mkdir -p "$d"
irm "$REG/ckad-hydra:v2"
pullbase alpine:3.20 registry:2

# Recreated every time, with no volume: the catalog starts empty, so
# verify's "is it in the registry?" check can only pass if you pushed.
crm ckad-registry
docker run -d --name ckad-registry -p "$REG_PORT:5000" registry:2 >/dev/null
echo "  empty throwaway registry running on $REG"

cat > "$d/Dockerfile" <<'EOF'
FROM alpine:3.20
RUN echo "hydra v2" > /version.txt
CMD ["cat", "/version.txt"]
EOF
echo "  q05 ready: $d"
