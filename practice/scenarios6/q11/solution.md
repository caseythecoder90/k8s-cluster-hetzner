# Q11 solution

```bash
k -n tiber get pods --show-labels     # confirm app=api / frontend / logs / ...
vim /course6/11/api-fence.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-fence
  namespace: tiber
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 80          # the port ON api
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: logs
      ports:
        - protocol: TCP
          port: 80          # the port ON logs
```

```bash
k apply -f /course6/11/api-fence.yaml
k -n tiber describe netpol api-fence      # prints the parsed Allowing/... blocks

API=$(k -n tiber get svc api     -o jsonpath='{.spec.clusterIP}')
LOG=$(k -n tiber get svc logs    -o jsonpath='{.spec.clusterIP}')
BIL=$(k -n tiber get svc billing -o jsonpath='{.spec.clusterIP}')

k -n tiber exec deploy/frontend -- wget -T 4 -qO- http://$API   # api-v1
k -n tiber exec deploy/scanner  -- wget -T 4 -qO- http://$API   # times out
k -n tiber exec deploy/api      -- wget -T 4 -qO- http://$LOG   # logs-v1
k -n tiber exec deploy/api      -- wget -T 4 -qO- http://$BIL   # times out
```

## What `policyTypes` actually does

`policyTypes` is the list of **directions this policy takes responsibility
for**. For each direction named there:

> the selected pods switch to default-deny in that direction, and only what
> the matching rule list explicitly allows gets through.

Directions **not** named are not touched by this policy at all — some other
policy may govern them, and if none does, they stay wide open.

That gives four combinations, and all four appear on exams:

| `policyTypes` | `ingress:` / `egress:` | Effect on the selected pods |
|---|---|---|
| `[Ingress]` | one `from:` rule | inbound restricted to that peer; **outbound untouched** |
| `[Ingress]` | *no rule*, or `ingress: []` | **all** inbound denied (the default-deny idiom) |
| `[Ingress, Egress]` | rules for both | both directions restricted |
| `[Ingress, Egress]` | rules for ingress only | inbound restricted, and **all outbound denied** |

The last row is the trap, and it is why this question makes you prove that
`api` can still reach `logs`. Adding `Egress` to `policyTypes` is not a
comment about your intentions — it is the switch that flips outbound to
default-deny. A rule list you did not write is not "no restriction", it is
"nothing is allowed".

The mirror-image mistake is just as common and quieter: writing a beautiful
`egress:` block and leaving `policyTypes: [Ingress]`. The API server accepts
it. `kubectl get -o yaml` shows your egress rules sitting there. They do
nothing whatsoever, because the direction is not governed. **If you write an
`egress:` block, put `Egress` in `policyTypes` in the same keystroke.**

(In practice `kubectl` fills `policyTypes` in for you from which blocks are
present when you omit the field entirely — but write it explicitly. On the
exam an explicit `policyTypes` is what shows you know which directions you
locked, and the moment you want a deny-all direction with no rules, the
defaulting cannot help you.)

## One policy, two directions, two perspectives

The single hardest habit is remembering that both rule lists are written
**from the selected pod's point of view**:

- `ingress.from` = who may open a connection **to** `api`; `ports` are ports
  **on api**.
- `egress.to` = who `api` may open a connection **to**; `ports` are ports **on
  the far end** (here, `logs`'s `80`).

And because NetworkPolicy is **stateful**, replies flow automatically. `api`
needs no egress rule to answer `frontend`, and `logs` needs no ingress policy
change to answer `api`. You only ever write a rule for the direction a
connection is *initiated* in.

## Why several policies would also "work" but is the wrong answer here

NetworkPolicies are purely additive: with two policies selecting `api`, a
connection is allowed if **either** permits it, and there is no deny rule and
no ordering. Splitting this into `api-ingress` + `api-egress` produces the
same behaviour — which is exactly why the task pins it to one object. Being
able to hold both directions in a single spec, with `policyTypes` on top
saying what you have taken over, is the thing being examined.

## Note on DNS

Every probe in this question connects to a ClusterIP, so nothing here needs
to resolve a name and no `:53` rule is required. Change one probe to
`http://logs` and this policy breaks instantly — see Q9. In real life an
egress policy almost always carries the kube-dns rule as well.
