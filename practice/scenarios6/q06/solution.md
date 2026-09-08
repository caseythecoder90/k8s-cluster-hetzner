# Q6 solution

Find the labels before writing a single selector — this is the step that makes
the difference between four minutes and fifteen:

```bash
k -n jordan get pods --show-labels
# jordan-api-...   app=jordan-api,...
# frontend-...     app=frontend,role=frontend
# batch-...        app=batch,role=batch
k -n jordan get svc jordan-api -o jsonpath='{.spec.ports}{"\n"}'
# [{"name":"api","port":80,"targetPort":8080},{"name":"admin","port":9090,"targetPort":9090}]
```

```yaml
# /course6/6/policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: jordan
spec:
  podSelector:              # WHO is protected
    matchLabels:
      app: jordan-api
  policyTypes:
    - Ingress
  ingress:
    - from:                 # WHO may connect
        - podSelector:
            matchLabels:
              role: frontend
      ports:                # WHERE they may connect
        - protocol: TCP
          port: 8080        # the CONTAINER's port, not the Service's 80
```

```bash
kubectl apply -f /course6/6/policy.yaml
APIIP=$(k -n jordan get pod -l app=jordan-api -o jsonpath='{.items[0].status.podIP}')
k -n jordan exec deploy/frontend -- wget -T 4 -qO- http://jordan-api        # ok
k -n jordan exec deploy/frontend -- wget -T 4 -qO- http://$APIIP:9090       # hangs
k -n jordan exec deploy/batch    -- wget -T 4 -qO- http://$APIIP:8080       # hangs
```

## The three questions every ingress rule answers

Read any NetworkPolicy in this order and it stops being intimidating:

| Question | Field | Here |
|---|---|---|
| Who is **protected**? | `spec.podSelector` | `app=jordan-api` |
| Which **direction**? | `spec.policyTypes` | Ingress |
| Who may **connect**? | `ingress[].from` | Pods labelled `role=frontend` |
| On which **port**? | `ingress[].ports` | TCP 8080 |

`spec.podSelector` and the `podSelector` inside `from:` are the same YAML shape
doing opposite jobs — target versus peer. Writing the target's labels in the
`from:` block (or vice versa) is the second most common mistake on these
questions, right behind the port.

Note that the policy protects `jordan-api` and nothing else. `frontend` and
`batch` are not selected by it, so they stay wide open — a policy is a
whitelist for *the Pods it selects*, not a Namespace-wide switch. And no rule
is needed for the replies: NetworkPolicy is stateful, so once
`frontend -> api:8080` is allowed, the response travels back on its own.

## Trap

**`ports:` in a NetworkPolicy is the target Pod's real listening port. It has
never heard of the Service.**

The Service publishes `80` and forwards to container `8080`, and the client
types `http://jordan-api` — port 80. It is completely natural to write
`port: 80` in the policy. But by the time the packet reaches the Pod, kube-proxy
has already rewritten the destination to `podIP:8080`, and that is the packet
Calico inspects. `port: 80` therefore matches nothing and the "allowed" client
is silently blocked — the policy looks right and the app is down.

Rule to keep: **NetworkPolicy ports are `targetPort` values.** When you write
one, go and read the Service's `targetPort` (or the container's
`containerPort`) and copy *that* number.

## Two ways to get the second half wrong

- **Omitting `ports:` altogether.** A `from:` with no `ports:` means "any port".
  `frontend` would keep its access to the admin endpoint on 9090 and
  requirement 2 fails, quietly, while requirement 1 looks perfect.
- **Deleting the Service's admin port.** That does make 9090 unreachable
  *through the Service*, and it is not a firewall: any Pod in the cluster can
  still hit `podIP:9090` directly. Removing a route is not the same as denying
  access, which is exactly why `verify.sh` probes the Pod IP.
