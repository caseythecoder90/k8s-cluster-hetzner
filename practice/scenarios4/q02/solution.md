# Q2 solution

Never guess value names — read them:

```bash
helm show values hk-charts/api --version 2.1.0
```

```yaml
replicaCount: 1
image: {...}
service:
  type: ClusterIP
  port: 80
  nodePort: ""
env: []
```

So the knobs are `replicaCount`, `service.type`, `service.nodePort` and the
`env` list.

## Option A — values file (cleanest for anything nested or list-shaped)

```bash
cat > /course4/2/values.yaml <<EOF
replicaCount: 3
service:
  type: NodePort
  nodePort: 30402
env:
  - name: LOG_LEVEL
    value: debug
EOF

helm install beryl-api hk-charts/api --version 2.1.0 \
  -n beryl --create-namespace -f /course4/2/values.yaml
```

## Option B — all on the command line

```bash
helm install beryl-api hk-charts/api --version 2.1.0 -n beryl --create-namespace \
  --set replicaCount=3 \
  --set service.type=NodePort --set service.nodePort=30402 \
  --set 'env[0].name=LOG_LEVEL,env[0].value=debug'
```

Nested keys use dots, list entries use `[index]`. Lists via `--set` get ugly
fast — that's when a values file wins.

## Check

```bash
helm -n beryl ls
helm -n beryl get values beryl-api           # exactly what you passed
k -n beryl get deploy,svc,pod
curl http://10.10.1.10:30402
```

## Traps

- `-n beryl` alone fails with *namespaces "beryl" not found* — Helm does not
  create Namespaces unless you add `--create-namespace`.
- `--version` is the **chart** version. Without it you get the newest (2.2.0)
  and fail step 1 even though everything else works.
- "Via Helm values" is graded with `helm get values`. Fixing the replica count
  afterwards with `kubectl scale` leaves Helm's record at 1 — and the next
  `helm upgrade` would put it back to 1.
- `helm install --dry-run` renders without installing if you want to preview.
