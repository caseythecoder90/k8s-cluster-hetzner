#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace chronos --dry-run=client -o yaml | kubectl apply -f -
kubectl -n chronos delete deployment chronos-app --ignore-not-found
kubectl -n chronos delete secret chronos-creds --ignore-not-found

kubectl -n chronos create secret generic chronos-creds \
  --from-literal=username=chronos-svc \
  --from-literal=password='S3cret-Pass!23'

echo "READY q15"
