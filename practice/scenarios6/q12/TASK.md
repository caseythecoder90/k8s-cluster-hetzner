# Q12 (topic: blue/green cutover)

Namespace `volga` is mid blue/green release. Deployment `checkout-blue` (3
replicas, pods labelled `track: blue`) serves every request through Service
`checkout`. Deployment `checkout-green` (3 replicas, pods labelled
`track: green`) is fully deployed and taking no traffic. A copy of the live
Service is at `/course6/12/checkout-svc.yaml`.

Green has passed validation. Cut over.

1. Make Service `checkout` send **100%** of its traffic to the green pods, in
   one step. Its name, type, port and target port must not change
2. Leave `checkout-blue` running and untouched — 3 ready replicas, still
   serving `blue-v1` — so the release can be rolled back instantly

Do not scale, delete, edit or restart either Deployment. Deployment
`checkout-green` must also stay at 3 replicas.

You can watch the result with:

```bash
CIP=$(kubectl -n volga get svc checkout -o jsonpath='{.spec.clusterIP}')
kubectl -n volga exec deploy/probe -- sh -c "for i in 1 2 3 4 5 6 7 8 9 10; do wget -qO- $CIP; done"
```

> Target: 4 minutes. There is no `strategy.type` for this, and the object you
> change is not a Deployment.
