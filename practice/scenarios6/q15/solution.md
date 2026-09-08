# Q15 solution

## See the steady state you are promoting from

```bash
k -n congo get deploy
k -n congo get endpoints feed                  # 4 IPs: 3 primary + 1 canary
k -n congo get pods -l tier=feed --show-labels # version=v1 x3, version=v2 x1
k -n congo describe svc feed                   # Selector: tier=feed
```

## Step 1 — roll the primary onto v2

The version lives in the container's `command` in this lab, so the promotion
is an edit of the pod template. Two labels change nothing and one changes:
`tier: feed` **stays**, `version` goes to `v2`.

```bash
k -n congo edit deploy feed-primary
```

```yaml
spec:
  replicas: 4                       # step 2, do it in the same edit
  selector:
    matchLabels:
      app: feed-primary             # untouched — immutable anyway
  template:
    metadata:
      labels:
        app: feed-primary
        tier: feed                  # KEEP. This is what Service feed selects.
        version: v2                 # was v1
    spec:
      containers:
        - name: web
          image: nginx:1-alpine
          command: ["/bin/sh","-c","echo feed-v2 > /usr/share/nginx/html/index.html && exec nginx -g 'daemon off;'"]
```

In a normal cluster, where versions are image tags, this whole step is one
command and it is the one to know:

```bash
k -n congo set image deploy/feed-primary web=myapp:2.0
```

Watch it land:

```bash
k -n congo scale deploy feed-primary --replicas=4     # if you did not do it in the edit
k -n congo rollout status deploy/feed-primary
```

## Step 3 — retire the canary

```bash
k -n congo delete deploy feed-canary
```

## Confirm

```bash
k -n congo get endpoints feed                 # 4 IPs, all feed-primary
VIP=$(k -n congo get svc feed -o jsonpath='{.spec.clusterIP}')
k -n congo exec deploy/probe -- sh -c \
  "i=0; while [ \$i -lt 20 ]; do wget -qO- $VIP; i=\$((i+1)); done"
# feed-v2 twenty times
k -n congo get deploy                          # feed-primary only
```

## What is being drilled

**A canary promotion is a rolling update of the primary plus a delete.** There
is no promotion object and no cutover step. The Service is never edited — not
once, in either direction. Contrast with blue/green, where the Service
selector *is* the operation.

**The shared label is what makes it seamless.** Because both Deployments'
pods carry `tier: feed` and the Service selects only that, the Endpoints list
is continuously repopulated as pods come and go:

| Moment | Endpoints of `feed` |
|---|---|
| start | 3 primary v1 + 1 canary v2 |
| during the roll | a shifting mix of primary v1, primary v2 and the canary — every one of them serving |
| after the roll | 4 primary v2 + 1 canary v2 |
| after the delete | 4 primary v2 |

At no point is the list empty, so at no point is there an outage. The
RollingUpdate defaults (`maxUnavailable: 25%`, `maxSurge: 25%`) guarantee
ready pods exist throughout, and the canary is still there absorbing traffic
while the primary churns. That is the whole reason you roll the primary
*before* deleting the canary and not after.

**Scale to 4 before or with the roll, not after.** Going from 3+1 to 4+0 keeps
capacity flat. Deleting the canary first and then scaling would leave you
briefly serving on 3 pods where you had 4.

## The trap

While editing the pod template it is very easy to rewrite the whole `labels:`
block as just `version: v2`, or to "tidy up" by dropping `tier: feed` now that
there is only one Deployment left. Either does the same thing:

- The new pods come up healthy. `kubectl get pods` is all green.
- None of them carries `tier: feed`, so the Service selects none of them.
- `k -n congo get endpoints feed` goes to `<none>` and the app is down, with
  no event, no CrashLoop, no error anywhere to point at it.

The label the Service selects on is a **contract**. It survives every version
change, and it is the last thing you delete, not the first. When you have
finished a promotion, the reflex is:

```bash
k -n congo get endpoints feed
```

Four IPs means you are done. `<none>` means you dropped the shared label.

## The other wrong answer

Deleting `feed-primary` and scaling `feed-canary` up to 4 produces the right
responses and passes a naive smoke test, but you have renamed your production
Deployment to `feed-canary` forever and have no primary to canary *against*
next time. The primary is the stable slot; you roll it forward and throw the
canary away.
