# Preview Q1 solution

```bash
helm install iris-web /course2/p1/iris-chart -n iris --set replicaCount=2
helm upgrade iris-web /course2/p1/iris-chart -n iris \
  --set replicaCount=2 --set image.tag=1.27-alpine
```

```bash
helm status iris-web -n iris
helm history iris-web -n iris
kubectl -n iris get deploy iris-web -o jsonpath='{.spec.replicas}{"\n"}{.spec.template.spec.containers[0].image}{"\n"}'
```

Trap: **`helm upgrade` does not remember previous `--set` flags** — each
invocation is a fresh render from `values.yaml` plus whatever you pass this
time. Omitting `--set replicaCount=2` on the upgrade would silently reset it
back to the chart's default (`1`). If you want values to persist across
upgrades without retyping them, use `-f custom-values.yaml` instead of
`--set`, or `helm upgrade --reuse-values` to carry forward the previous
release's values and only override what's changing.

`helm rollback iris-web 1 -n iris` reverts to revision 1 if needed — Helm's
own version of `kubectl rollout undo`, keyed by numeric revision, not tags.
