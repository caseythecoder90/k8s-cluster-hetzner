#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace zeus --dry-run=client -o yaml | kubectl apply -f -
kubectl -n zeus delete cronjob zeus-backup --ignore-not-found

echo "READY q03"
