# Q4 solution

## Pass 1 — strategic merge

```yaml
# /course5/4/overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: nickel
resources:
  - ../../base
patches:
  - path: patch.yaml
```

```yaml
# /course5/4/overlays/dev/patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker              # the BASE name
  annotations:
    maintainer: nickel-team
spec:
  template:
    spec:
      containers:
        - name: app         # merge key — match the container, change one field
          resources:
            limits:
              memory: 256Mi
```

The patch is a *fragment of the real manifest*, self-identifying by
`apiVersion` + `kind` + `metadata.name`. No `target:`. Merging is additive:
naming `limits` does not remove `requests`, and naming one container does not
remove the others.

## Pass 2 — JSON 6902

```yaml
patches:
  - target:
      kind: Deployment
      name: worker
    patch: |-
      - op: add
        path: /spec/template/spec/containers/0/resources/limits
        value:
          memory: 256Mi
      - op: add
        path: /metadata/annotations
        value:
          maintainer: nickel-team
```

## The gotcha the second pass exists to teach

`add` writes a key **into a map that already exists** — it does not create the
map on the way. The base has `resources:` (so adding `limits` under it is
fine) but it has **no `annotations:` at all**. So:

```yaml
- op: add
  path: /metadata/annotations/maintainer     # ✗ fails: no annotations map
  value: nickel-team
```

```yaml
- op: add
  path: /metadata/annotations                # ✓ add the map itself
  value: {maintainer: nickel-team}
```

Strategic merge has no equivalent problem — it builds intermediate maps for
you. That asymmetry is the reason to reach for strategic merge first whenever
the task lets you choose.

Two more rules worth reciting while you are here:

- `replace` **errors** when the path does not exist; `add` never does.
  When unsure whether the target is there, use `add` — it creates *or*
  overwrites.
- `remove` takes no `value:`.
