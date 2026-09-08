# Q8 solution

```bash
k -n rhine get pods --show-labels
k -n oder  get pods --show-labels
k get ns rhine --show-labels        # kubernetes.io/metadata.name=rhine
```

```yaml
# /course6/8/policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-rhine-web
  namespace: oder
spec:
  podSelector:
    matchLabels:
      app: oder-api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:                                 # ONE list item...
            matchLabels:
              role: web
          namespaceSelector:                           # ...two fields. AND.
            matchLabels:
              kubernetes.io/metadata.name: rhine
      ports:
        - protocol: TCP
          port: 80
```

Note the indentation of `namespaceSelector`: it lines up with `podSelector`'s
own key, **not** with the `-`. There is no dash in front of it. That is the
entire difference.

```bash
kubectl apply -f /course6/8/policy.yaml
APIIP=$(k -n oder get pod -l app=oder-api -o jsonpath='{.items[0].status.podIP}')
k -n rhine exec deploy/rhine-web   -- wget -T 4 -qO- http://$APIIP   # ok
k -n rhine exec deploy/rhine-batch -- wget -T 4 -qO- http://$APIIP   # hangs
k -n oder  exec deploy/oder-web    -- wget -T 4 -qO- http://$APIIP   # hangs
```

## The rule, in two lines

- **Separate `-` items under `from:` are OR-ed** (union). Each item is an
  independent way in.
- **Fields inside one `-` item are AND-ed** (intersection). The source must
  satisfy all of them at once.

So the dash is the operator. Written out, the wrong answer is:

```yaml
    - from:
        - podSelector:
            matchLabels:
              role: web
        - namespaceSelector:            # <-- this dash flips AND into OR
            matchLabels:
              kubernetes.io/metadata.name: rhine
```

which means *"anything labelled `role=web` **in oder**, OR anything at all in
`rhine`"* — and that is why this question has exactly the three clients it has:

| Client | AND (correct) | OR (the trap) |
|---|---|---|
| `rhine-web` — role=web, in rhine | allowed | allowed |
| `rhine-batch` — role=batch, in rhine | **blocked** | allowed (matched the Namespace alone) |
| `oder-web` — role=web, in oder | **blocked** | allowed (matched the label alone) |

The OR version does not error, does not warn, and looks almost identical in
`kubectl describe netpol`. It simply lets in two Pods you meant to keep out.
`describe` is still the fastest way to check yourself, because it prints the
peers as separate bullets when they are OR-ed and on one line when they are
ANDed:

```bash
k -n oder describe netpol allow-rhine-web
#   Allowing ingress traffic:
#     To Port: 80/TCP
#     From:
#       NamespaceSelector: kubernetes.io/metadata.name=rhine
#       PodSelector: role=web            <-- same "From:" entry = ANDed
```

Two bullets each beginning with `From:` means you wrote the union.

## How to get it right under time pressure

Translate the English into set language *before* touching YAML:

- "from the web pods **in** namespace rhine" -> **∩** -> one item, two fields
- "from the web pods, **and also from** anything in rhine" -> **∪** -> two items

The word **"in"** is almost always an intersection. "and also" / "or" /
"as well as" is almost always a union.

And remember why the AND is even necessary: a `podSelector` in a `from:` block
is scoped to the policy's own Namespace by default. Pair it with a
`namespaceSelector` and the pod selector is instead applied to the Pods of the
selected Namespaces. That is what makes `role=web` mean *rhine's* web Pods
rather than *oder's*.

## Trap

`ipBlock` is the exception to all of the above: it is its own peer type and
**never** combines with `podSelector`/`namespaceSelector` inside one item.
Writing an `ipBlock` next to a `podSelector` under the same dash is rejected by
the API server. If you need "these pods or that CIDR", it must be two items —
a union — and there is no way to express "a pod that also has this IP".
