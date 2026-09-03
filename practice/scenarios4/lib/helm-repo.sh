#!/bin/bash
# Helm chart repository for Exam Set 4, sourced by common.sh.
#
# killer.sh serves its exam charts from a tiny HTTP server on the control plane
# (localhost:6000). This does the same on localhost:6100 with three practice
# charts, several versions each, so "upgrade to a newer version" and
# "install version X, not the latest" are real choices:
#
#   hk-charts/api    1.0.0  2.0.0  2.1.0  2.2.0   (nginx:1-alpine)
#   hk-charts/nginx  1.0.0  1.1.0  1.2.0          (nginx:1-alpine)
#   hk-charts/redis  0.5.0  0.6.0  0.7.1          (redis:7-alpine)
#
# Every chart renders one Deployment + one Service. values.yaml is commented so
# `helm show values` is worth reading (that's the habit the questions train).
# Files live under /course4/_repo on the control plane.

# ensure_helm_repo — build + serve + `helm repo add hk-charts`. Idempotent:
# a second call only refreshes the repo index.
ensure_helm_repo() {
  $SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
REPO=/course4/_repo/charts
SRC=/course4/_repo/src

if curl -sf -m 3 http://localhost:6100/index.yaml >/dev/null 2>&1 && [[ -f "$REPO/api-2.2.0.tgz" ]]; then
  helm repo add hk-charts http://localhost:6100 --force-update >/dev/null
  helm repo update >/dev/null
  exit 0
fi

sudo mkdir -p /course4/_repo && sudo chown -R deploy:deploy /course4/_repo
rm -rf "$SRC" "$REPO"; mkdir -p "$SRC" "$REPO"

mkchart() { # mkchart <name> <description> <image-repo> <image-tag> <containerPort>
  local n=$1 d=$2 repo=$3 tag=$4 port=$5
  mkdir -p "$SRC/$n/templates"
  cat > "$SRC/$n/Chart.yaml" <<EOF
apiVersion: v2
name: $n
description: $d
type: application
version: 0.0.0
appVersion: "0.0"
EOF
  cat > "$SRC/$n/values.yaml" <<EOF
# Default values for the $n chart.

replicaCount: 1

image:
  repository: $repo
  tag: "$tag"
  pullPolicy: IfNotPresent

containerPort: $port

service:
  type: ClusterIP
  port: $port
  # Only used when type is NodePort. Empty = let Kubernetes pick one.
  nodePort: ""

# Extra environment variables for the main container, e.g.
# env:
#   - name: LOG_LEVEL
#     value: debug
env: []

resources:
  requests:
    cpu: 10m
    memory: 16Mi
EOF
  cat > "$SRC/$n/templates/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  labels:
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
    helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ .Chart.Name }}
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
        - name: main
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.containerPort }}
          {{- with .Values.env }}
          env:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
EOF
  cat > "$SRC/$n/templates/service.yaml" <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
  labels:
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  type: {{ .Values.service.type }}
  selector:
    app.kubernetes.io/instance: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.containerPort }}
      {{- if and (eq .Values.service.type "NodePort") .Values.service.nodePort }}
      nodePort: {{ .Values.service.nodePort }}
      {{- end }}
EOF
  cat > "$SRC/$n/templates/NOTES.txt" <<'EOF'
Release {{ .Release.Name }} ({{ .Chart.Name }}-{{ .Chart.Version }}) is installed in namespace {{ .Release.Namespace }}.
EOF
}

mkchart api   "Internal API service (practice chart)"   nginx 1-alpine 80
mkchart nginx "Plain nginx web server (practice chart)" nginx 1-alpine 80
mkchart redis "Redis cache (practice chart)"            redis 7-alpine 6379

# appVersion differs per chart version so the APP VERSION column of
# `helm search repo --versions` and `helm ls` actually tells versions apart.
pkg() { helm package "$SRC/$1" --version "$2" --app-version "$3" -d "$REPO" >/dev/null; }
pkg api 1.0.0 1.0;    pkg api 2.0.0 2.0;    pkg api 2.1.0 2.1;   pkg api 2.2.0 2.2
pkg nginx 1.0.0 1.25; pkg nginx 1.1.0 1.26; pkg nginx 1.2.0 1.27
pkg redis 0.5.0 7.0;  pkg redis 0.6.0 7.2;  pkg redis 0.7.1 7.4
helm repo index "$REPO" --url http://localhost:6100 >/dev/null

pkill -f "http.server 6100" >/dev/null 2>&1 || true
sleep 1
setsid nohup python3 -m http.server 6100 --directory "$REPO" --bind 127.0.0.1 \
  >/course4/_repo/serve.log 2>&1 </dev/null &
for _ in $(seq 1 20); do curl -sf -m 2 http://localhost:6100/index.yaml >/dev/null && break; sleep 0.5; done

helm repo add hk-charts http://localhost:6100 --force-update >/dev/null
helm repo update >/dev/null
REMOTE
}

# force_release_status <ns> <release> <revision> <status>
# Helm stores each release revision as a Secret whose payload is
# base64(base64(gzip(json))). Rewriting the status inside it (and the Secret's
# status label) reproduces exactly what a helm process killed mid-operation
# leaves behind: a release `helm ls` hides and only `helm ls -a` shows.
force_release_status() {
  $SSH_CP "bash -s" <<REMOTE
set -euo pipefail
SEC="sh.helm.release.v1.$2.v$3"
kubectl -n $1 get secret "\$SEC" -o jsonpath='{.data.release}' | base64 -d | base64 -d | gunzip > /tmp/rel.json
sed -i 's/"status":"[a-z-]*"/"status":"$4"/' /tmp/rel.json
NEW=\$(gzip -c /tmp/rel.json | base64 -w0 | base64 -w0)
kubectl -n $1 patch secret "\$SEC" --type=json -p="[{\"op\":\"replace\",\"path\":\"/data/release\",\"value\":\"\$NEW\"}]" >/dev/null
kubectl -n $1 label secret "\$SEC" status=$4 --overwrite >/dev/null
rm -f /tmp/rel.json
REMOTE
}
