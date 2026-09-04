# Q14 solution

No `k create` generator for StatefulSet — copy the skeleton:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: olympus-svc
  namespace: olympus
spec:
  clusterIP: None            # <- what makes it "headless"
  selector:
    app: olympus
  ports:
    - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: olympus-app
  namespace: olympus
spec:
  serviceName: olympus-svc   # must name the headless Service above
  replicas: 3
  selector:
    matchLabels:
      app: olympus
  template:
    metadata:
      labels:
        app: olympus
    spec:
      containers:
        - name: nginx
          image: nginx:1-alpine
          resources: {requests: {cpu: 10m, memory: 16Mi}}
```

```bash
k apply -f statefulset.yaml
k -n olympus get pods -w        # watch: olympus-app-0 creates and becomes Ready
                                 # BEFORE olympus-app-1 starts — ordered, not parallel
```

```bash
k -n olympus run dns-test --image=busybox:1 -it --rm --restart=Never -- \
  nslookup olympus-app-0.olympus-svc.olympus.svc.cluster.local
```

The concept: a **headless Service** (`clusterIP: None`) doesn't load-balance
— DNS returns each backing Pod's IP directly instead of one virtual IP. Paired
with a StatefulSet, each Pod also gets a **stable, predictable name**
(`<statefulset>-0`, `-1`, `-2`, ...) that survives Pod restarts (unlike a
Deployment's random-suffixed names). That combination is what lets you address
`olympus-app-0` specifically and reliably — the pattern every clustered
database (Postgres replicas, Kafka brokers, etcd) relies on.

Trap: StatefulSet Pods start **one at a time, in order**, waiting for each to
be Ready before the next begins (unless `podManagementPolicy: Parallel` is
set) — so `readyReplicas` climbing to 3 takes longer than an equivalent
Deployment would.
