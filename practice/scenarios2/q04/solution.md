# Q4 solution

```bash
k -n hermes set image deploy/hermes-canary nginx=nginx:1.31-alpine
k -n hermes scale deploy/hermes-canary --replicas=1
```

Verify traffic really is split — the Service's endpoints should list pods
from both Deployments:

```bash
k -n hermes get endpointslices -l kubernetes.io/service-name=hermes-svc
```

The concept: canary ≠ blue-green. Blue-green is an instant, atomic cutover
(flip the Service selector). Canary is a **gradual ramp** — both versions run
behind the *same* selector simultaneously, and you shift the ratio by scaling
each Deployment's replica count, not by touching the Service at all. 4 stable
+ 1 canary ≈ 20% of requests hit the new version. To promote the canary fully,
scale canary up and stable down to 0 over time; to abort, scale canary back
to 0 — either way, the Service definition never changes.
