# Q8 solution

```bash
helm search repo hk-charts/redis --versions           # 0.7.1, 0.6.0, 0.5.0
helm pull hk-charts/redis --version 0.6.0 --untar -d /course4/8
ls /course4/8/redis                                   # Chart.yaml  templates/  values.yaml
```

`helm pull` alone downloads `redis-0.6.0.tgz`; `--untar` extracts it into a
directory named after the chart; `-d` (`--destination`) says where.

```bash
vim /course4/8/redis/values.yaml                      # replicaCount: 2
# or: sed -i 's/^replicaCount: 1/replicaCount: 2/' /course4/8/redis/values.yaml

helm install ruby-cache /course4/8/redis -n ruby --create-namespace
helm -n ruby ls                                       # redis-0.6.0
k -n ruby get deploy ruby-cache                       # 2/2
helm -n ruby get values ruby-cache                    # USER-SUPPLIED VALUES: null
```

## What "from the local directory" means to Helm

The chart argument is resolved by shape:

| You write | Helm treats it as |
|---|---|
| `hk-charts/redis` | repo/chart — looks it up in the repo index |
| `/course4/8/redis` or `./redis` | a chart **directory** on disk |
| `redis-0.6.0.tgz` | a packaged chart on disk |
| `oci://registry/charts/redis` | an OCI registry chart |

Editing `values.yaml` inside the chart changes the chart's **defaults**, so
`helm get values` shows nothing user-supplied — that's the difference between
this and `--set replicaCount=2`, and it's what the verify checks.

## Also useful

```bash
helm show values hk-charts/redis --version 0.6.0     # read defaults without pulling
helm show chart hk-charts/redis                      # Chart.yaml
helm lint /course4/8/redis                           # sanity-check a chart you edited
helm template x /course4/8/redis | head -30          # render the edited chart
```
