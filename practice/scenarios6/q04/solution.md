# Q4 solution

## The diagnosis

```bash
k -n hudson get endpoints hudson-web
# NAME         ENDPOINTS                            AGE
# hudson-web   10.244.1.7:8080,10.244.2.9:8080      2m
```

Endpoints exist — so the selector is right, the Pods are Ready, and this is not
Q1's fault. But look at the **port** they were written with: `:8080`. Now look
at what the container actually runs:

```bash
k -n hudson get deploy hudson-web -o jsonpath='{.spec.template.spec.containers[0].ports}{"\n"}'
# [{"containerPort":80,"protocol":"TCP"}]
k -n hudson exec deploy/probe -- wget -T 3 -qO- http://<podIP>:80     # works
k -n hudson exec deploy/probe -- wget -T 3 -qO- http://<podIP>:8080   # refused
```

kube-proxy is faithfully DNAT-ing every request for the Service to
`podIP:8080`, and nothing in that Pod is listening there. The kernel answers
with a TCP RST, which is why the failure is **instant**.

## The fix

```bash
vim /course6/4/service.yaml       # targetPort: 8080  ->  80
kubectl apply -f /course6/4/service.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hudson-web
  namespace: hudson
spec:
  type: ClusterIP
  selector:
    app: hudson-web
  ports:
    - port: 80
      targetPort: 80        # was 8080
```

or

```bash
kubectl -n hudson patch svc hudson-web -p '{"spec":{"ports":[{"port":80,"targetPort":80}]}}'
```

Then re-read the Endpoints — the port there changes with `targetPort`, which is
the confirmation you want before you re-test:

```bash
k -n hudson get endpoints hudson-web        # ...:80
k -n hudson exec deploy/probe -- wget -qO- http://hudson-web
```

## The pair — this is the whole point of Q1 and Q4 together

Both are "the Service does not work". They are told apart in one command and
three seconds:

| `get endpoints` says | The fault is | Where to look |
|---|---|---|
| `<none>` | the **selector** doesn't match any Ready Pod | `describe svc` selector vs `get pods --show-labels`; then Pod readiness |
| IPs, and connections are **refused** | `targetPort` points at a port nothing listens on | the Endpoints' port vs the container's real port |
| IPs, and connections **hang / time out** | something is dropping packets | `kubectl get netpol -n <ns>` |

Refused vs hung is not a detail — it is the diagnostic. A **refusal** is a live
host actively saying "nothing here", so the packets are arriving: routing and
Endpoints are fine and the port is wrong. A **hang** means the packets are being
dropped silently, which is what a firewall does; on this cluster that is
Calico enforcing a NetworkPolicy (Q5 onwards).

## Trap

`targetPort` **defaults to the value of `port`**. That default is why this
class of bug is so common: somebody writes a Service for an app on 8080,
copies it for an app on 80, changes `port` and forgets `targetPort` — or omits
`targetPort` entirely on a Service whose `port` is not the container's port.
The Service still creates cleanly, still gets Endpoints, still looks healthy in
`kubectl get svc`. Nothing tells you until a client connects.

The habit that prevents it: after creating any Service, run
`kubectl get endpoints <name>` and read **both** halves of what it prints — the
addresses *and* the port.
