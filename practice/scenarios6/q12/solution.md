# Q12 solution

## Look at the wiring first

```bash
k -n volga get deploy,svc
k -n volga get pods --show-labels          # track=blue on 3, track=green on 3
k -n volga describe svc checkout           # Selector: track=blue, Endpoints = 3 blue IPs
```

## The cutover — one field

Imperatively, which is what you want under time pressure:

```bash
k -n volga patch svc checkout -p '{"spec":{"selector":{"track":"green"}}}'
```

Or edit the file and re-apply:

```yaml
# /course6/12/checkout-svc.yaml
spec:
  selector:
    track: green        # the only line that changes
```

```bash
k apply -f /course6/12/checkout-svc.yaml
```

## Confirm

```bash
k -n volga describe svc checkout        # Selector: track=green; Endpoints are the 3 green IPs
k -n volga get endpoints checkout

CIP=$(k -n volga get svc checkout -o jsonpath='{.spec.clusterIP}')
k -n volga exec deploy/probe -- sh -c "for i in 1 2 3 4 5 6 7 8 9 10; do wget -qO- $CIP; done"
# green-v2 ten times
```

Rollback, should you need it, is the same command with `blue`. That is the
entire value proposition of the pattern.

## What is being drilled

**Blue/green is a Service-selector flip.** Two complete Deployments run side
by side; exactly one of them is selected by the Service at any moment. There
is no `strategy.type: BlueGreen` — `strategy.type` only ever takes `Recreate`
or `RollingUpdate`, and neither of those is this. The pattern is assembled
from primitives you already have: two Deployments, one distinguishing label,
one Service.

**The switch is atomic from the Service's point of view.** The endpoints
controller recomputes the EndpointSlice against the new selector, and in-flight
connections to blue drain while every new connection lands on green. Users
never see a mixed version the way they would during a RollingUpdate — that
clean break is the reason to pay for double the pods.

**The label scheme.** Each pod carries two labels doing different jobs:

| Label | Job |
|---|---|
| `app: checkout-blue` / `app: checkout-green` | each Deployment's own `selector.matchLabels`, so it owns only its own pods |
| `track: blue` / `track: green` | what the **Service** selects — the thing you flip |

If a Deployment's own selector were `track: <colour>` alone that would still
work, but the two jobs must stay distinguishable in your head: the Deployment
selector owns pods, the Service selector routes traffic.

**A Service `selector` is a flat map** of label key to value. No
`matchLabels:`, no `matchExpressions:` — those belong to Deployment and
ReplicaSet selectors, and crossing the two forms is the classic slip:

```yaml
spec:
  selector:
    matchLabels:            # WRONG on a Service
      track: green
```

The Service selector is typed `map[string]string`, so a nested map here is
rejected outright (`cannot unmarshal object into field ... of type string`).
That is the lucky version. The unlucky version is a selector that is
well-formed but matches no pod — `k -n volga get endpoints checkout` prints
`<none>`, the Service answers nothing, and there is no error anywhere. Check
the endpoints after every selector change; it is a two-second habit that
catches the whole class of mistake.

## The trap: leave blue alone

The most common wrong answer is to "cut over" by scaling `checkout-blue` to 0,
or by editing blue's image to the new version. Both make the probe show
green-only, and both are wrong:

- Scaling blue to 0 means the rollback is now a rollout with a cold start,
  not a selector flip. You have thrown away the only thing blue/green buys
  you.
- Editing blue's image is a RollingUpdate wearing a blue/green costume — the
  two versions briefly serve traffic together, which is precisely what
  blue/green exists to avoid.

Blue keeps running, warm and ready, until you have decided the release is
good. **Then** you delete it to reclaim the capacity — as a separate,
deliberate act, not as part of the cutover.
