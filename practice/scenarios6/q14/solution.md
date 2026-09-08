# Q14 solution

## Look at what selects what

```bash
k -n zambezi describe svc shop                 # Selector: tier=shop
k -n zambezi get pods --show-labels            # primary pods: app, tier=shop, version=v1
cat /course6/14/shop-canary.yaml               # canary pods: app, version=v2 ... and no tier
```

That missing `tier: shop` is the whole first half of the question.

## Step 1 — give the canary the shared label

```yaml
# /course6/14/shop-canary.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-canary
  namespace: zambezi
spec:
  replicas: 2                    # step 3
  selector:
    matchLabels:
      app: shop-canary           # UNCHANGED — this owns the canary's own pods
  template:
    metadata:
      labels:
        app: shop-canary
        version: v2
        tier: shop               # ADDED — this is what Service shop selects
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          command: ["/bin/sh","-c","echo shop-v2 > /usr/share/nginx/html/index.html && exec nginx -g 'daemon off;'"]
          ports:
            - containerPort: 80
          resources:
            requests: {cpu: 5m, memory: 12Mi}
```

```bash
k apply -f /course6/14/shop-canary.yaml
```

## Step 3 — the arithmetic

The split is `canary pods / total pods`. You need ~25% with 8 pods total:

```
canary / 8 = 0.25  ->  canary = 2,  primary = 8 - 2 = 6
```

```bash
k -n zambezi scale deploy shop-primary --replicas=6
k -n zambezi scale deploy shop-canary  --replicas=2     # or leave it at 2 in the file
k -n zambezi rollout status deploy/shop-primary
k -n zambezi rollout status deploy/shop-canary
```

## Confirm

```bash
k -n zambezi get endpoints shop                       # 8 IPs
k -n zambezi get pods -l tier=shop --show-labels      # 6 x version=v1, 2 x version=v2

VIP=$(k -n zambezi get svc shop -o jsonpath='{.spec.clusterIP}')
k -n zambezi exec deploy/probe -- sh -c \
  "i=0; while [ \$i -lt 40 ]; do wget -qO- $VIP; i=\$((i+1)); done"
# a mix of shop-v1 and shop-v2, roughly 3:1
```

## What is being drilled

**The Service selects the shared label; the version label is for you.** Every
pod in a canary carries two labels doing two different jobs:

| Label | Who reads it |
|---|---|
| `tier: shop` | the **Service** — this is what puts both Deployments behind one ClusterIP |
| `version: v1` / `version: v2` | **you** (`get pods -l version=v2`), and nothing else routes on it |

Selecting `version` on the Service would defeat the entire pattern — you would
be back to one version at a time, which is blue/green.

**Each Deployment's own `spec.selector` must keep owning only its own pods.**
Two Deployments whose selectors both matched `tier: shop` would each see 8
pods where they expect their own count, and fight: scale one and the other
deletes pods to compensate. `spec.selector` is immutable after creation, so
this is not a mistake you fix — you delete the Deployment and start over.
Hence: shared label in the **pod template**, distinct label in the
**Deployment selector**.

**The split is pod count and nothing else.** A Service load-balances roughly
evenly across all ready Endpoints, so `2/8 = ~25%`. That is the only knob
vanilla Kubernetes gives you. Shifting the canary up is `kubectl scale`; the
finest split you can express is `1 / total pods`, so ~1% would need 100 pods.
Weighted routing ("99/1 with one pod each") is what a service mesh — Istio,
Linkerd — or a controller like Argo Rollouts exists for. Not on CKAD, but
knowing *why* the native approach is coarse is.

## The trap

`kubectl apply -f shop-canary.yaml` as shipped works perfectly. The Deployment
becomes available, `kubectl get pods` shows a happy `shop-canary` pod, nothing
anywhere reports a problem — and the canary receives **exactly zero requests**,
because Service `shop` selects `tier: shop` and the canary's pods do not carry
it. A canary that gets no traffic is not a canary; it is a pod costing you
memory.

The diagnostic is one command, and it is the same one as in blue/green:

```bash
k -n zambezi get endpoints shop
```

Count the IPs. If it is 6 and not 8, the Service is not seeing the canary, and
the answer is always a label on the **pod template** — not on the Deployment's
`metadata.labels`, which nothing routes on.

## Why verify.sh does not check for exactly 25%

kube-proxy picks a backend at random per connection. Over 60 requests a true
25% split easily lands anywhere from 8 to 25 hits. Asserting an exact
percentage would produce a red check for a perfectly correct answer, so the
assertion is what is actually guaranteed: the Endpoints contain pods from both
Deployments in a 6:2 ratio, and both versions really answer.
