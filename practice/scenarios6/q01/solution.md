# Q1 solution

## The diagnosis, in the order you should always do it

```bash
k -n amazon get svc amazon-web                 # it exists, it has a ClusterIP
k -n amazon get endpoints amazon-web           # ENDPOINTS: <none>   <-- the answer
k -n amazon get pods --show-labels             # app=amazon-web
k -n amazon describe svc amazon-web            # Selector: app=amazon-api
```

`ENDPOINTS: <none>` on a Service whose Pods are Ready means exactly one thing:
**the Service's selector matches no Pods.** The Service selector says
`app=amazon-api`; the Pods carry `app=amazon-web`.

## The fix

```bash
vim /course6/1/service.yaml      # selector.app: amazon-api  ->  amazon-web
kubectl apply -f /course6/1/service.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: amazon-web
  namespace: amazon
spec:
  type: ClusterIP
  selector:
    app: amazon-web        # was amazon-api
  ports:
    - port: 80
      targetPort: 80
```

Or, without leaving the shell:

```bash
kubectl -n amazon patch svc amazon-web -p '{"spec":{"selector":{"app":"amazon-web"}}}'
```

Confirm, then prove it:

```bash
k -n amazon get endpoints amazon-web           # now lists 2 Pod IPs
k -n amazon exec deploy/probe -- wget -qO- http://amazon-web
```

## What is being drilled

**A Service has no link to a Deployment.** It never references one, and the
Deployment never references the Service. The only connection is:
`Service.spec.selector` -> Pod labels. The endpoints controller watches Pods,
matches them against every Service selector in the Namespace, and writes the
matching Pod IPs into an `Endpoints` / `EndpointSlice` object. kube-proxy
programmes those IPs. Nothing else happens.

That gives you a three-rung diagnostic ladder for *any* "the Service does not
work" question, and rung one is always the same:

| Symptom | Meaning | Look at |
|---|---|---|
| `ENDPOINTS: <none>` | selector matches no Pod, or no Pod is Ready | `describe svc` selector vs `get pods --show-labels` |
| Endpoints listed, connection **refused** | wrong `targetPort` (see Q4) | container's real port |
| Endpoints listed, connection **hangs** | a NetworkPolicy is dropping it | `get netpol` |

`kubectl get endpoints <svc>` costs you three seconds and splits the problem
space in half. Do it before you read a single line of YAML.

Two follow-ups worth knowing:

- A Pod that matches the selector but is **not Ready** is held out of
  `.subsets[].addresses` (it appears under `notReadyAddresses`). So empty
  Endpoints can also mean "a readiness probe is failing" — `get pods` tells you
  which of the two it is immediately.
- `Endpoints` is the old API and `EndpointSlice` is its replacement;
  `kubectl get endpoints` still works on 1.33 and is the faster thing to type.
  `kubectl get endpointslice -l kubernetes.io/service-name=amazon-web` shows
  the same data if you ever meet a cluster where `endpoints` is gone.

## Trap

The obvious "fix" is to relabel the Deployment's Pods to `app=amazon-api` so
they match the broken Service. It works, and it is the wrong answer: you have
changed the identity of a running workload to accommodate a typo in a Service,
and every other selector that pointed at `app=amazon-web` (other Services,
NetworkPolicies, PodDisruptionBudgets) silently stops matching. When a selector
and a set of labels disagree, the **selector** is the cheap, local, reversible
thing to change.
