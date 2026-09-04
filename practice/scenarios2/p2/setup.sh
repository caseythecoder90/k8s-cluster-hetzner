#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace nike --dry-run=client -o yaml | kubectl apply -f -
kubectl -n nike delete deployment nike-web --ignore-not-found

$SSH_CP "sudo mkdir -p /course2/p2/base && sudo rm -rf /course2/p2/overlay && sudo chown -R deploy:deploy /course2/p2 && \
cat > /course2/p2/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF
cat > /course2/p2/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nike-web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nike-web
  template:
    metadata:
      labels:
        app: nike-web
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          resources:
            requests: {cpu: 10m, memory: 16Mi}
EOF
cat > /course2/p2/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nike-svc
spec:
  selector:
    app: nike-web
  ports:
    - port: 80
      targetPort: 80
EOF
"

echo "READY p2 — base lives at /course2/p2/base on: $SSH_CP  (you create overlay/prod)"
