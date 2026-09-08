# Q16 solution

```bash
ls /course5/16/base                        # deployment.yaml service.yaml kustomization.yaml
grep -n 'name:' /course5/16/base/deployment.yaml    # know the base names before you type
cd /course5/16/overlays/prod
vim kustomization.yaml
```

## Pass 1 — strategic merge

```yaml
# /course5/16/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: mercury            # 1
namePrefix: hg-               # 2

resources:
  - ../../base

replicas:                     # 3
  - name: gauge               #    BASE name
    count: 3

images:                       # 4
  - name: nginx               #    IMAGE name, not the container 'web'
    newTag: "1.27-alpine"

labels:                       # 5 — metadata only, selectors untouched
  - pairs:
      env: prod
    includeSelectors: false

configMapGenerator:           # 6
  - name: gauge-config        #    the name the base REFERENCES
    literals:
      - UNITS=metric
      - SCALE=celsius

patches:                      # 7
  - path: patch.yaml
```

```yaml
# /course5/16/overlays/prod/patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gauge                 # BASE name again
spec:
  template:
    spec:
      containers:
        - name: web           # merge key — matches, does not replace
          env:
            - name: READ_ONLY
              value: "true"   # quoted: env values are strings
```

```bash
kubectl kustomize .                     # READ IT: hg-gauge, hg-gauge-config-<hash>,
                                        # 3 replicas, nginx:1.27-alpine, both env vars
kubectl apply -k .
k -n mercury get deploy,svc,cm --show-labels
k -n mercury get deploy hg-gauge -o jsonpath='{.spec.template.spec.containers[0].env}'; echo
```

## Pass 2 — JSON 6902 for deliverable 7

Delete `patch.yaml` and swap the `patches:` block for:

```yaml
patches:
  - target:
      kind: Deployment
      name: gauge             # BASE name, and it is a regex
    patch: |-
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: READ_ONLY
          value: "true"
```

`/env/-` appends to the existing list — the base already has an `env:` with
`MODE` in it, so the list exists and `add` lands after it. If the container
had **no** `env:` at all you would have to create the list itself:
`op: add`, `path: /spec/template/spec/containers/0/env`,
`value: [{name: READ_ONLY, value: "true"}]`.

Two ways to get this wrong and lose the point:

- `path: /.../env/0` — that **inserts** at the front, shifting `MODE` down.
  Harmless here, fatal when the task says "change the first env var" (that is
  `replace .../env/0/value`).
- `op: replace`, `path: /.../env` — wipes `MODE`.

## The trap: which name goes where

Transformers run in a fixed order, and `namePrefix` runs **after** the fields
that match by name. So four of the seven deliverables refer to `gauge` /
`gauge-config` / `nginx` even though the applied objects are called
`hg-gauge` and `hg-gauge-config-<hash>`:

| Field | Name to write | Why |
|---|---|---|
| `replicas[].name` | `gauge` | base name; prefix not applied yet |
| a patch's `metadata.name` (SMP) | `gauge` | same |
| a 6902 `target.name` | `gauge` | same |
| `configMapGenerator[].name` | `gauge-config` | the name the base **references** |
| `images[].name` | `nginx` | the image, never the container |

Write `hg-gauge` in any of the first three and Kustomize matches nothing —
**and does not error**. The build renders, the apply succeeds, and the
replica count or the patch has simply vanished. This is the single most
expensive silent failure in Kustomize, which is why `kubectl kustomize .`
before `apply -k` is not optional.

## The rest of the sharp edges in this one question

- **`labels:` not `commonLabels:`.** "Without any selector changing" is the
  exam's tell. `commonLabels` writes into `spec.selector.matchLabels`, and on
  a Deployment that already exists that is `field is immutable`.
- **The prefix reaches generated objects too**: `hg-` + `gauge-config` +
  hash. You never type any part of that; the nameReference transformer
  rewrites `volumes[].configMap.name` for you.
- **`value: "true"`** — unquoted it is a bool, and the API server rejects the
  Pod spec with `cannot unmarshal bool into Go struct field EnvVar.value of
  type string`. Same for ports and any numeric-looking value.
- **`newTag` alone** changes the tag; swapping the repository as well needs
  `newName`.

## The order to type it in under time

`apiVersion`/`kind` → `resources:` → then the deliverables top to bottom,
rendering once when the transformer fields are in and once more after the
patch. Two renders, one apply.
