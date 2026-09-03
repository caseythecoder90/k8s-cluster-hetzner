# Q6 solution

`helm template` renders a chart to stdout and never touches the cluster —
no release, no Secret, nothing to `helm ls`. It takes the same value flags as
`helm install`:

```bash
cd /course4/6
cat prod-values.yaml                                  # replicaCount: 2 — we override that
helm template pearl-web ./chart -n pearl -f prod-values.yaml --set replicaCount=3 > pearl-web.yaml
grep -n "replicas\|nodePort\|image:" pearl-web.yaml   # sanity check the render
```

`--set` wins over `-f`, which wins over the chart's `values.yaml`, so
`replicas: 3` ends up in the file while the NodePort and image tag come from
the values file.

```bash
k -n pearl apply -f pearl-web.yaml
k -n pearl get deploy,svc,pod
helm -n pearl ls -a                                   # empty, as required
```

## Traps

- **`-n pearl` on `helm template` doesn't put a namespace in the YAML.** It
  only sets `.Release.Namespace` for templates that use it; this chart
  doesn't. The manifests carry no `metadata.namespace`, so the `kubectl apply`
  needs its own `-n pearl` or everything lands in `default`.
- A chart path is a **directory** (`./chart`) or a `.tgz`, given as a path;
  `chart` alone would be looked up as a repo chart name and fail.
- `helm install --dry-run` also prints rendered manifests, but it contacts the
  cluster and prints extra text (NOTES, status header) around the YAML — a
  file made from it is not clean YAML. `helm template` is the right tool for
  "save the manifests".
- The rendered file is the graded artifact as much as the cluster state.
  Check it before applying.
