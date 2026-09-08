# Q15 solution

The method is the answer: **render, read one error, fix it, render again.**
Never guess a second fix while an error is still on screen.

```bash
cd /course5/15/overlays/staging
cat kustomization.yaml
ls                       # app.conf  kustomization.yaml
kubectl kustomize .
```

### Round 1 — `unknown field`

```
error: invalid Kustomization: json: unknown field "configmapGenerator"
```

The kustomization is parsed **strictly** and before anything else, so a
mistyped key always surfaces first — no path has even been looked at yet.
The field is `configMapGenerator`, camel-cased on the *Map*:

```yaml
configMapGenerator:
  - name: pigment-config
    files:
      - app.config
```

### Round 2 — a path in `resources:`

```
error: accumulating resources: accumulation err='accumulating resources from
'../base': evalsymlink failure on '/course5/15/overlays/base' :
lstat /course5/15/overlays/base: no such file or directory'
```

Read the path in the message, not the one in the file: it tried
`/course5/15/overlays/base`. Relative paths resolve from the directory of the
kustomization that lists them, and this one lives in
`/course5/15/overlays/staging`, so the base is **two** hops up:

```yaml
resources:
  - ../../base
```

### Round 3 — a path in the generator

```
error: ... loading generator: '/course5/15/overlays/staging/app.config':
no such file or directory
```

(the wording moves around between kubectl versions; `app.config` and
`no such file` are the parts that matter). The file on disk is `app.conf` and
the task forbids renaming it, so fix the reference:

```yaml
configMapGenerator:
  - name: pigment-config
    files:
      - app.conf
```

### The finished overlay

```yaml
# /course5/15/overlays/staging/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: cadmium
namePrefix: stg-

resources:
  - ../../base

replicas:
  - name: pigment        # the BASE name — namePrefix has not run yet
    count: 2

configMapGenerator:
  - name: pigment-config # the BASE's reference name — the prefix is added after
    files:
      - app.conf
```

```bash
kubectl kustomize .            # renders: stg-pigment, stg-pigment-config-<hash>
kubectl apply -k .
k -n cadmium get deploy,svc,cm
```

## Reading the errors

| Message | Where the fault is |
|---|---|
| `unknown field "x"` | a key in a `kustomization.yaml`. Never in a manifest. |
| `no such file or directory` / `evalsymlink failure` | a path in `resources:`, `patches[].path`, `files:`, `envs:`. The message prints the path it *tried* — that is your hop count. |
| `recursed accumulation of path` | the failing path is inside the **base**, not the overlay you ran. |
| `must be a directory` / `unable to find one of 'kustomization.yaml'...` | you pointed `-k` at a file, or at a directory with no kustomization. |
| `may not add resource with an already registered id` | two resources, or a generator, with the same name — see `behavior:`. |
| `is not in or below` | a path escaping the kustomization root; copy the file in. |

`unknown field` is the one to burn in. Kustomize does not accept near-misses:
`configmapGenerator`, `commonLabel`, `nameprefix`, `Resources`, `patch:` where
you meant `patches:` — all the same error, all fixed in the kustomization.

## Bonus: what the prefix does to a generated ConfigMap

`namePrefix: stg-` is applied to **every** resource in the build, generated
ones included, so the ConfigMap comes out as `stg-pigment-config-<hash>` —
prefix, base name, then hash. The Deployment still just says
`configMap: {name: pigment-config}` in the base, and the nameReference
transformer rewrites it to the full built name. That is why the generator's
`name:` must be the name the base **references**, never the prefixed one.
