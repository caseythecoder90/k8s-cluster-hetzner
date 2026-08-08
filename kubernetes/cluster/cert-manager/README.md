# cert-manager

Automates TLS: watches Ingress objects annotated with
`cert-manager.io/cluster-issuer`, obtains Let's Encrypt certs via HTTP-01,
stores them in the Secrets the Ingress `tls:` blocks name, renews ~30 days
before expiry. Replaces the certbot container + renewal cron from the old VPS.

## Install (once)

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml
kubectl -n cert-manager wait --for=condition=Available deployment --all --timeout=120s
kubectl apply -f kubernetes/cluster/cert-manager/clusterissuer.yaml
```

## Watching issuance at cutover

```bash
kubectl get certificate -A          # READY True when issued
kubectl describe certificate -n personal-website caseyrquinn-com-tls
kubectl get challenges -A           # in-flight ACME challenges, if stuck
```

Issuance only works once the domain's DNS points at this cluster (Let's
Encrypt must reach the challenge URL through the internet). Rate limits are
generous but real (50 certs/domain/week) — don't loop-recreate on failure.
