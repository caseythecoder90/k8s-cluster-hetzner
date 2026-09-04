#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace olympus --dry-run=client -o yaml | kubectl apply -f -
kubectl -n olympus delete statefulset olympus-app --ignore-not-found
kubectl -n olympus delete service olympus-svc --ignore-not-found

echo "READY q14"
