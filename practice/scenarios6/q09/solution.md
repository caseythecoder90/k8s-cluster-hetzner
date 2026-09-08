# Q9 solution

## Look first

```bash
k -n seine get pods --show-labels
k get ns kube-system --show-labels
k -n kube-system get pods -l k8s-app=kube-dns          # the CoreDNS pods
```

## The policy

```bash
vim /course6/9/egress.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: checkout-egress
  namespace: seine
spec:
  podSelector:
    matchLabels:
      app: checkout
  policyTypes:
    - Egress                      # Egress ONLY — no Ingress
  egress:
    # 1. the business rule
    - to:
        - podSelector:
            matchLabels:
              app: payments
      ports:
        - protocol: TCP
          port: 80

    # 2. the rule the task is really about
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:            # NO dash -> same peer -> AND
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

```bash
k apply -f /course6/9/egress.yaml
k -n seine describe netpol checkout-egress

# prove it, both directions
k -n seine exec deploy/checkout -- nslookup payments.seine.svc.cluster.local
k -n seine exec deploy/checkout -- wget -T 4 -qO- http://payments.seine.svc.cluster.local
k -n seine exec deploy/checkout -- wget -T 4 -qO- http://analytics    # must hang, then fail
```

## The trap: an Egress policy silently kills DNS

A NetworkPolicy is a **whitelist for the pods it selects**. The instant
`Egress` appears in `policyTypes`, every outbound packet from `checkout` that
is not explicitly allowed is dropped — and *DNS is outbound traffic*. The pod
was using UDP `:53` to CoreDNS all along; nobody wrote a rule for it because
nobody had to.

What it looks like when you get this wrong is the reason it costs people the
mark: it does **not** look like a firewall. `wget http://payments` reports
`bad address 'payments'`, or hangs and dies on a resolver timeout. You go and
re-check your `podSelector`, your ports, your labels — and they are all
correct. The connection was never attempted, because the *name* never
resolved.

**The tell:** the same request works by ClusterIP and fails by name. Whenever
you see that split after adding a policy, it is the DNS rule, every time.

Two details in the DNS rule that are worth memorising:

- **`namespaceSelector` + `podSelector` under ONE dash.** They are ANDed, so
  the peer is "the kube-dns pods **in** kube-system". Put a dash in front of
  `podSelector` and you have ORed them: "anything in kube-system, **or**
  anything labelled `k8s-app: kube-dns` anywhere". That still works, so the
  probe goes green — but it is far wider than you meant, and it is the exact
  dash mistake the examiner is watching for.
- **UDP *and* TCP 53.** DNS is UDP until a response is too big, then the
  resolver retries over TCP. Allow one and you have a policy that works right
  up until it does not. `protocol:` defaults to TCP, so the UDP entry must be
  spelled out.
- `kubernetes.io/metadata.name` is set automatically on every Namespace, so
  selecting `kube-system` by name needs no labelling of your own. (The
  CoreDNS pods carry `k8s-app: kube-dns` even though the Deployment is named
  `coredns` — check with `--show-labels` rather than guessing.)

## Why selecting `app: payments` works when you connect to a Service IP

`checkout` connects to `payments`'s **ClusterIP**, but the policy names the
*pods*. That is fine: kube-proxy DNATs the ClusterIP to a backend pod IP
before the packet reaches the policy engine, so what the egress rule sees is
the real pod as the destination. Two consequences worth having straight:

- Never write `ipBlock: {cidr: <ClusterIP>/32}` for a Service. The policy is
  evaluated after the translation, so that rule matches nothing.
- The egress `port` is the **pod's** port after DNAT (the container's `80`),
  not the Service's port. Here both are `80`; when a Service maps `8080` ->
  `80`, the policy wants `80`.

## Scope

`podSelector` in `spec` (not in a rule) says *which pods the policy attaches
to*. `audit` is not selected, so it is not restricted at all — that is what
the last two checks prove. `podSelector: {}` would attach to every pod in the
Namespace and take `audit` down with it.
