# Q7 solution

```bash
k get ns nile --show-labels
# NAME   STATUS   AGE   LABELS
# nile   Active   2m    kubernetes.io/metadata.name=nile
```

```yaml
# /course6/7/policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-nile
  namespace: mekong
spec:
  podSelector:
    matchLabels:
      app: mekong-db
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: nile
      ports:
        - protocol: TCP
          port: 80
```

```bash
kubectl apply -f /course6/7/policy.yaml
DBIP=$(k -n mekong get pod -l app=mekong-db -o jsonpath='{.items[0].status.podIP}')
k -n nile   exec deploy/nile-client   -- wget -T 4 -qO- http://$DBIP   # ok
k -n nile   exec deploy/nile-batch    -- wget -T 4 -qO- http://$DBIP   # ok
k -n mekong exec deploy/mekong-client -- wget -T 4 -qO- http://$DBIP   # hangs
```

## Why `podSelector` cannot do this job

A `podSelector` inside `from:` is evaluated **against Pods in the policy's own
Namespace** unless a `namespaceSelector` widens the search. So the obvious-
looking rule:

```yaml
      - podSelector:
          matchLabels:
            role: client
```

means "Pods labelled `role=client` **in mekong**" — it lets in exactly the one
client you wanted to keep out (`mekong-client`) and keeps out the one you
wanted (`nile-client`). Precisely backwards, and it fails silently: the YAML is
valid, the policy applies, and the wrong Pod has access.

Labels are not unique across Namespaces. Anybody who can create a Pod in any
Namespace can put `role=client` on it. **A `podSelector`-only rule is a
Namespace-local statement**, and the moment the peer lives somewhere else you
need a `namespaceSelector`.

## `kubernetes.io/metadata.name`

Since v1.22 the API server stamps every Namespace with
`kubernetes.io/metadata.name: <its own name>`, and it is immutable — you cannot
rename it or remove it. That gives you a reliable way to say "this exact
Namespace" with **zero setup**, which is exactly what you want in an exam: no
`kubectl label ns`, no dependency on someone else's labelling convention.

```bash
k get ns --show-labels                  # the fastest way to see what you can select on
k get ns nile -o jsonpath='{.metadata.labels}{"\n"}'
```

Two neighbours worth knowing:

- `namespaceSelector: {}` — **all** Namespaces. Not "none".
- `namespaceSelector` with no `podSelector` beside it — every Pod in the
  matching Namespaces, which is what requirement 1 asks for here.

## Trap

The trap in this question is over-tightening. It is tempting to write both
selectors:

```yaml
      - podSelector:
          matchLabels:
            role: client
        namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: nile
```

That reads well and blocks `mekong-client` correctly — but it also blocks
`nile-batch`, and the task said **any** Pod in `nile`. Adding a selector you
were not asked for is as wrong as leaving one out; a firewall rule that is too
tight breaks an application just as surely as one that is too loose, and it
breaks it in a way that looks like someone else's bug.

Translate the English literally before you type: *"any Pod in Namespace nile"*
has one subject — the Namespace — so the rule has one selector.

(That two-field spelling is not wasted knowledge, though. It is the
intersection form, and Q8 is entirely about it.)
