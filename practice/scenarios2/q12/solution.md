# Q12 solution

No imperative generator for NetworkPolicy — copy the skeleton from
kubernetes.io ("Network Policies" page) and edit:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: demeter-backend-policy
  namespace: demeter
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 80
```

```bash
k apply -f netpol.yaml
```

Test live — this is worth doing even when not asked, because "the YAML
looks right" and "it actually blocks traffic" are different claims:

```bash
k -n demeter exec deploy/demeter-frontend -- wget -qO- --timeout=5 http://demeter-backend-svc
k -n demeter-other exec demeter-other-client -- wget -qO- --timeout=5 http://demeter-backend-svc.demeter.svc.cluster.local
```

First should return HTML; second should **time out** (NetworkPolicy drops
silently — no "connection refused", it just hangs until the wget timeout).

Traps:
- **No `podSelector` under `from:`** means "no pod restriction" — i.e. allow
  from anywhere matching the other criteria. You must nest `podSelector`
  *inside* the `from:` list item.
- **Missing `namespaceSelector`** in the `from:` entry means "same namespace
  only" by default — which is exactly what this question wants, so don't
  add one. Adding a `namespaceSelector: {}` here would *broaden* it to all
  namespaces, the opposite of the requirement.
- A Pod with **no NetworkPolicy selecting it** allows all traffic (default
  allow) — policies are additive/restrictive only once at least one policy
  selects a pod. `demeter-frontend` has no policy, so nothing restricts its
  *outbound* traffic; only `demeter-backend`'s *inbound* is restricted here.
