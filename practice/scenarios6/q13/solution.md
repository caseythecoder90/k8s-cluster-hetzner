# Q13 solution

## Step 0 — see where you are

```bash
k -n yangtze get deploy,svc
k -n yangtze get pods --show-labels          # track=blue x2, track=green x2
k -n yangtze describe svc orders             # Selector: track=blue
```

## Step 1 — a test Service, so green can be validated with zero user traffic

Green is running but nothing routes to it. Give it a private front door:

```bash
k -n yangtze create service clusterip orders-test --tcp=80:80 $do > /course6/13/orders-test.yaml
vim /course6/13/orders-test.yaml     # fix the selector
k apply -f /course6/13/orders-test.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: orders-test
  namespace: yangtze
spec:
  type: ClusterIP
  selector:
    track: green          # green ONLY
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
```

> `kubectl create service clusterip` writes `selector: {app: orders-test}` —
> the generated selector is always the Service's own name, which matches
> nothing here. Fix it or the Service comes up with no Endpoints. Always
> `describe` a generated Service before you trust it.

Validate:

```bash
k -n yangtze get endpoints orders-test           # 2 green Pod IPs
TIP=$(k -n yangtze get svc orders-test -o jsonpath='{.spec.clusterIP}')
OIP=$(k -n yangtze get svc orders      -o jsonpath='{.spec.clusterIP}')
k -n yangtze exec deploy/probe -- wget -qO- http://$TIP     # orders-v2
k -n yangtze exec deploy/probe -- wget -qO- http://$OIP     # orders-v1, users unaffected
```

That is the validation window: real pods, real network, real Service — and
not one production request touched them.

## Step 2 — cut over

```bash
k -n yangtze patch svc orders -p '{"spec":{"selector":{"track":"green"}}}'
k -n yangtze get endpoints orders          # now the 2 green IPs
k -n yangtze exec deploy/probe -- wget -qO- http://$OIP    # orders-v2
```

## Step 3 — record it

```bash
k -n yangtze get svc orders -o jsonpath='{.spec.selector}' > /course6/13/cutover.txt
cat /course6/13/cutover.txt      # {"track":"green"}
```

## Step 4 — roll back

```bash
k -n yangtze patch svc orders -p '{"spec":{"selector":{"track":"blue"}}}'
k -n yangtze get endpoints orders                          # back to the 2 blue IPs
k -n yangtze exec deploy/probe -- wget -qO- http://$OIP     # orders-v1
```

One command. No image pull, no scheduling, no readiness wait — the blue pods
never stopped being ready. Elapsed time to full recovery is however long it
takes kube-proxy to reprogram, which is well under a second.

## What is being drilled

**The rollback is the cutover, backwards.** Both are `patch svc ... selector`.
If you can say that in one sentence in the exam, you have the pattern.

**Keeping blue running is what buys the instant rollback**, and it is the
step people skip because it feels wasteful. The moment you scale blue to 0 to
"reclaim capacity", your rollback becomes a rollout: schedule 2 pods, pull the
image, wait for readiness. During an incident that is minutes you do not have.
Blue stays warm for as long as your bake time says, and only then gets deleted
— deliberately, as its own decision.

**Two Services is the normal shape.** The live Service routes users; a
separate test Service (or a port-forward, for a quick look) routes you. They
differ only in their selector. A single Service cannot do both jobs, because
a Service selector is all-or-nothing — there is no "10% to green" without a
service mesh, which is exactly the gap Istio/Linkerd fill and exactly why they
exist.

**Note the asymmetry with canary.** Blue/green validates green with *zero*
traffic and switches all at once; canary validates with a *slice* of real
traffic. Blue/green never exposes users to a mixed version; canary does, on
purpose.

## The trap

`kubectl create service clusterip <name>` generates `selector: app=<name>`.
For `orders-test` that is `app: orders-test` — a label no pod in this
Namespace carries. The Service is created successfully, gets a ClusterIP,
looks completely healthy in `k get svc`, and serves nothing. The one-line
diagnostic is always the same:

```bash
k -n yangtze get endpoints orders-test
```

`<none>` means the selector matches no ready pod. Check it after every Service
you create and after every selector you flip.
