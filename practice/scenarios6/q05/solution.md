# Q5 solution

```bash
vim /course6/5/policy.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: indus
spec:
  podSelector: {}         # every Pod in indus
  policyTypes:
    - Ingress             # ...and only ingress
```

```bash
kubectl apply -f /course6/5/policy.yaml
k -n indus describe netpol default-deny-ingress
```

```
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    <none> (Selected pods are isolated for ingress connectivity)
  Not affecting egress traffic
```

Read the last two lines back to yourself — that is the whole answer, in the
tool's own words.

Prove both halves:

```bash
WEBIP=$(k -n indus get pod -l app=indus-web -o jsonpath='{.items[0].status.podIP}')
k -n indus exec deploy/indus-client -- wget -T 4 -qO- http://$WEBIP     # hangs, then fails
k -n indus exec deploy/indus-client -- nslookup kubernetes.default      # still works
```

## What is being drilled

**Selection is the deny.** A NetworkPolicy is a pure allow-list, so the way you
express "deny" in core Kubernetes is to *select* a Pod for a direction and then
list no rules for it. There is no `action: Deny` — that is Calico's CRD, not
`networking.k8s.io/v1`.

Three rules follow from that, and they are the whole of this question:

1. **`podSelector: {}` means every Pod in the policy's Namespace.** An empty
   selector matches everything; it is not "no Pods". This is also why it keeps
   working for Pods created tomorrow — nothing here is a list.
2. **A direction is only affected if it appears in `policyTypes`.** Ingress is
   now default-deny in `indus`; egress was never named, so it is untouched and
   stays wide open. That asymmetry is deliberate and is the lesson.
3. **A policy is Namespace-scoped.** It selects Pods in its own Namespace only,
   which is why the traffic it denies includes traffic from `indus-client`, a
   Pod sitting right next to the target.

Also worth saying plainly: policies are **additive** across objects. Adding
this default-deny does not overrule anything — a second policy that allows
`role=frontend` on 8080 would punch a hole straight through it, because a
connection is permitted if *any* policy selecting the Pod allows it. Deny-all
plus targeted allows is the normal production shape, and you will meet it in
Q6.

## Trap

The tempting, symmetric-looking version:

```yaml
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress        # <-- this is the trap
```

That is a legitimate policy — a full lockdown — but it is not what was asked,
and it breaks the Namespace in a way that does not look like a networking
problem. Naming `Egress` with no `egress:` rules makes outbound default-deny
too, so every Pod immediately loses **DNS**: CoreDNS lives in `kube-system`,
port 53, and reaching it is egress. Applications then fail with
`Name or service not known` or a 30-second hang on connect, and nobody's first
guess is the ingress policy they just wrote.

The reflex to build: *the moment `Egress` appears in `policyTypes`, you owe the
Namespace a `:53` rule.*

```yaml
  egress:
    - to:
        - namespaceSelector: {}
      ports:
        - {protocol: UDP, port: 53}
        - {protocol: TCP, port: 53}
```

Here, the correct answer is simply not to name `Egress` at all.

One more thing that is not a bug: `kubectl exec` and `kubectl port-forward`
still work against these Pods. That traffic originates on the Pod's own node
from the kubelet, and NetworkPolicy does not police it. If you "test" a deny
rule with `port-forward` you will conclude your policy does nothing. Always
test from a Pod.
