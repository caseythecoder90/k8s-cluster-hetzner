# Q12 solution

JSON 6902 is "operation + path + value". Paths are JSON Pointers: every
`/` is one level down, list elements are addressed by index, and `-` means
"after the last element".

```bash
cd /course4/12/overlays/dev
k -n jasper get deploy jasper-worker -o yaml | less    # confirm env order and annotation names
vim kustomization.yaml
```

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: jasper
resources:
  - ../../base
patches:
  - target:
      kind: Deployment
      name: jasper-worker
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/env/0/value
        value: stream
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: DEBUG
          value: "true"
      - op: remove
        path: /metadata/annotations/jasper.io~1legacy-owner
```

```bash
kubectl kustomize .            # check env and annotations in the output
kubectl apply -k .
k -n jasper get deploy jasper-worker -o jsonpath='{.spec.template.spec.containers[0].env}{"\n"}{.metadata.annotations}{"\n"}'
```

## The three traps, one per operation

1. **`replace` needs an existing path.** `/env/0/value` exists, so replace is
   right. To edit only the value, point *into* the element — replacing
   `/env/0` would need the whole `{name, value}` object again.
2. **`"true"` must be quoted.** Env values are strings; an unquoted `true`
   becomes a YAML boolean and the API server rejects the Deployment
   (*cannot unmarshal bool into string*). Same for numbers.
3. **`/` inside a key is escaped as `~1`** (and `~` as `~0`). Without it,
   `/metadata/annotations/jasper.io/legacy-owner` means a key `legacy-owner`
   under a map called `jasper.io` — which doesn't exist, so the remove fails.

JSON 6902 needs a `target:` — unlike a strategic merge patch, the op list
has no `kind`/`name` of its own.

## Same thing in a file

```yaml
patches:
  - path: env-patch.yaml
    target:
      kind: Deployment
      name: jasper-worker
```

with `env-patch.yaml` holding just the `- op:` list. Either layout passes.
