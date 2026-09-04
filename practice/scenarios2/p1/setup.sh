#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace iris --dry-run=client -o yaml | kubectl apply -f -
$SSH_CP "helm uninstall iris-web -n iris >/dev/null 2>&1 || true"

# A minimal, fully local chart — no internet/repo dependency, matches how
# killer.sh actually does Helm questions (chart files provided locally).
$SSH_CP "sudo mkdir -p /course2/p1/iris-chart/templates && sudo chown -R deploy:deploy /course2/p1 && \
cat > /course2/p1/iris-chart/Chart.yaml <<'EOF'
apiVersion: v2
name: iris-chart
description: Minimal practice chart
version: 0.1.0
appVersion: \"1.0\"
EOF
cat > /course2/p1/iris-chart/values.yaml <<'EOF'
replicaCount: 1
image:
  repository: nginx
  tag: 1-alpine
EOF
cat > /course2/p1/iris-chart/templates/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
        - name: web
          image: \"{{ .Values.image.repository }}:{{ .Values.image.tag }}\"
          resources:
            requests: {cpu: 10m, memory: 16Mi}
EOF
cat > /course2/p1/iris-chart/templates/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
spec:
  selector:
    app: {{ .Release.Name }}
  ports:
    - port: 80
      targetPort: 80
EOF
"

echo "READY p1 — chart lives at /course2/p1/iris-chart on: $SSH_CP"
