# Q2 solution

```bash
k -n danube get pods --show-labels          # confirm the label before you write the selector
vim /course6/2/service.yaml
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: danube-web
  namespace: danube
spec:
  type: NodePort
  selector:
    app: danube-web
  ports:
    - port: 8080          # the ClusterIP answers here
      targetPort: 80      # nginx listens here, inside the Pod
      nodePort: 30602     # every node answers here, from outside
```

```bash
kubectl apply -f /course6/2/service.yaml
k -n danube get svc danube-web              # 8080:30602/TCP
k -n danube get endpoints danube-web        # two Pod IPs, port 80
curl http://10.10.1.10:30602
```

## The three numbers

Read them as a chain, outside to inside:

```
client ──> node:30602 ──> ClusterIP:8080 ──> Pod:80
             nodePort        port            targetPort
```

| Field | Whose port is it? | Range | Optional? |
|---|---|---|---|
| `nodePort` | every **node**, reachable from outside the cluster | 30000–32767 | yes — omit it and the cluster allocates one |
| `port` | the **Service** (its ClusterIP, and its DNS name) | any | **no** |
| `targetPort` | the **container** | any | yes — defaults to the same value as `port` |

Two consequences that cause most of the mistakes:

- **`targetPort` defaults to `port`.** Leave it out here and the Service tries
  to deliver to Pod port 8080, where nothing is listening: Endpoints are
  populated, and every connection is refused. That is Q4's fault, arrived at by
  accident.
- **A NodePort Service is still a ClusterIP Service.** It gets a ClusterIP and
  a DNS name as well as the node port; `type: NodePort` only adds the outside
  door. There is no such thing as "NodePort instead of ClusterIP".

## The imperative route, and where it stops

```bash
kubectl -n danube expose deployment danube-web \
  --name=danube-web --type=NodePort --port=8080 --target-port=80 --dry-run=client -o yaml \
  > /course6/2/service.yaml
```

`expose` reads the Deployment's Pod labels and writes the selector for you —
that is the part worth having. But **`expose` cannot set a specific
`nodePort`**; it always lets the cluster allocate one. So generate, then edit
the file to add `nodePort: 30602`, then apply. Do not `expose` straight into
the cluster and try to patch afterwards under time pressure — one file, one
`apply`, is fewer moves.

If you have already created it and only need the node port fixed:

```bash
kubectl -n danube patch svc danube-web \
  -p '{"spec":{"ports":[{"port":8080,"targetPort":80,"nodePort":30602}]}}'
```

The whole `ports` list is replaced by that patch, so every field has to be in
it — a strategic merge on a list keyed by `port` still needs the key present.

## Trap

`nodePort` must be inside `30000–32767` (the default `--service-node-port-range`)
and must not already be taken by another Service anywhere in the cluster. Both
failures come back as an `apply` error, not a silent misconfiguration, so read
what the API server says: *"provided port is not in the valid range"* and
*"provided port is already allocated"* are two different bugs.
