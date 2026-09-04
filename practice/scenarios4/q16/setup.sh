#!/bin/bash
source "$(dirname "$0")/../common.sh"

nswipe obsidian obsidian-dev
mkcourse /course4/16
$SSH_CP "bash -s" <<'REMOTE'
set -euo pipefail
rm -rf /course4/16/base /course4/16/overlays /course4/16/components
mkdir -p /course4/16/base /course4/16/overlays/dev /course4/16/overlays/prod /course4/16/components/monitoring
cat > /course4/16/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: obsidian-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: obsidian-app
  template:
    metadata:
      labels:
        app: obsidian-app
    spec:
      containers:
        - name: app
          image: nginx:1-alpine
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
EOF
cat > /course4/16/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: obsidian-app
spec:
  selector:
    app: obsidian-app
  ports:
    - port: 80
      targetPort: 80
EOF
cat > /course4/16/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF
cat > /course4/16/components/monitoring/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
resources:
  - configmap.yaml
patches:
  - path: patch-metrics.yaml
EOF
cat > /course4/16/components/monitoring/configmap.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: monitoring-config
data:
  SCRAPE_INTERVAL: "30s"
EOF
cat > /course4/16/components/monitoring/patch-metrics.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: obsidian-app
spec:
  template:
    spec:
      containers:
        - name: app
          env:
            - name: METRICS_ENABLED
              value: "true"
EOF
for env in dev prod; do
  ns=obsidian; [[ $env == dev ]] && ns=obsidian-dev
  cat > /course4/16/overlays/$env/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: $ns
resources:
  - ../../base
EOF
  kubectl apply -k /course4/16/overlays/$env >/dev/null
done
REMOTE
fingerprint q16-fixed "/course4/16/base/*.yaml" "/course4/16/components/monitoring/*.yaml"

echo "READY q16 — dev and prod deployed without the component"
