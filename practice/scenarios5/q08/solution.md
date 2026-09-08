# Q8 solution

Look at the base before writing a single op — the question is decided by
what is already in the manifest:

```bash
cat /course5/8/base/deployment.yaml
kubectl kustomize /course5/8/overlays/prod | grep -nE "labels|env|image"
```

| Change | Is the path in the base? | Op |
|---|---|---|
| `LOG_LEVEL` → `debug` | yes, `/…/env/0/value` | `replace` (or `add`) |
| `imagePullPolicy` | **no** | `add` — `replace` would error |
| label `retired` | yes, `/metadata/labels/retired` | `remove` |

```yaml
# /course5/8/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: chrome
resources:
  - ../../base
patches:
  - target:
      kind: Deployment
      name: plating
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/env/0/value
        value: debug
      - op: add
        path: /spec/template/spec/containers/0/imagePullPolicy
        value: Always
      - op: remove
        path: /metadata/labels/retired
```

```bash
kubectl kustomize /course5/8/overlays/prod       # renders = every path resolved
kubectl apply -k /course5/8/overlays/prod
kubectl -n chrome get deploy plating -o jsonpath='{.metadata.labels}{"\n"}'
```

## The op table, which is the whole question

| op | path missing | path present | takes `value:` |
|---|---|---|---|
| `add` | **creates it** | **overwrites** it | yes |
| `replace` | **errors** | overwrites it | yes |
| `remove` | **errors** | deletes it | **no** |

Read the middle column again: `add` overwrites an existing value perfectly
happily. That is why **`add` is the safe default** — it is the only op that
is correct whether or not the path is already there. `replace` buys you
nothing except a build failure when you guessed wrong about the base. The
only reason to write `replace` is to say "I have checked, this must already
exist" — a useful assertion when you are editing a base you did not write.

Three ways this goes wrong:

1. `- op: replace` + `path: /…/imagePullPolicy` → the build stops with
   `replace operation does not apply: doc is missing key`. The **build**
   fails, so nothing at all reaches the cluster — including the two ops that
   were fine.
2. `- op: remove` with a `value:` under it. `remove` takes a path and
   nothing else; a stray `value:` is at best ignored and at worst a parse
   error. And a `remove` on a path that isn't there fails the whole build —
   render and grep before you write one.
3. `- op: remove` + `path: /metadata/labels` — that deletes the entire
   labels map, taking `app: plating` with it. Point at the **key**, not at
   the map that holds it.

## The other half of the same rule

`add` writes a key into a map **that already exists**; it does not build the
map on the way. If the Deployment had no `labels:` at all, then

```yaml
- op: add
  path: /metadata/labels/tier      # ✗ no labels map to add into
  value: plating
```

fails, and you add the map itself instead:

```yaml
- op: add
  path: /metadata/labels
  value: {tier: plating}
```

Here `imagePullPolicy` sits directly under the container, which exists, so
one `add` is enough.
