#!/bin/bash
source "$(dirname "$0")/../common.sh"

kubectl create namespace dionysus --dry-run=client -o yaml | kubectl apply -f -
kubectl -n dionysus delete pvc dionysus-pvc --ignore-not-found
kubectl delete pv dionysus-pv --ignore-not-found

$SSH_CP "sudo mkdir -p /mnt/data/dionysus"

echo "READY q13"
