# Q7 solution

## Pass 1 — strategic merge

```yaml
# /course5/7/overlays/prod/patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: refinery
spec:
  template:
    spec:
      containers:
        - name: app              # merge key: finds the container
          args:                  # scalar list: REPLACES the base list entirely
            - "--mode=stream"
            - "--level=debug"
            - "--retries=3"      # unchanged — but it must still be written
            - "--timeout=60s"
```

```yaml
# /course5/7/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: iron
resources:
  - ../../base
patches:
  - path: patch.yaml
```

```bash
kubectl kustomize . | grep -A6 "args:"     # read it before applying
kubectl apply -k .
kubectl -n iron logs deploy/refinery | tail -1
```

## Pass 2 — JSON 6902

Two spellings, both correct. Per element:

```yaml
patches:
  - target:
      kind: Deployment
      name: refinery
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/args/0
        value: "--mode=stream"
      - op: replace
        path: /spec/template/spec/containers/0/args/1
        value: "--level=debug"
      - op: add
        path: /spec/template/spec/containers/0/args/-
        value: "--timeout=60s"
```

`--retries=3` is not mentioned at all here: JSON 6902 edits *positions*, so an
untouched index keeps its value. Or replace the list in one op:

```yaml
      - op: replace
        path: /spec/template/spec/containers/0/args
        value: ["--mode=stream", "--level=debug", "--retries=3", "--timeout=60s"]
```

## The rule this question exists to teach

**Scalar lists have no merge key.** `containers`, `env`, `ports`, `volumes`
and `volumeMounts` merge element-by-element on `name`. `command:` and `args:`
are lists of plain strings — there is nothing to match on, so a strategic
merge **replaces the whole list**.

So the two strategies behave in opposite ways here, and the reflex you build
on keyed lists is exactly the one that burns you:

| | keyed list (`containers`) | scalar list (`args`) |
|---|---|---|
| strategic merge | merges by `name` | replaces wholesale |
| what you must write | only the changed fields | **every element you want to keep** |

## The trap

Writing only what changed:

```yaml
          args:
            - "--mode=stream"
            - "--level=debug"
```

renders an `args` list of **two** entries. `--retries=3` is gone and
`--timeout=60s` was never added — nothing errors, the Pod stays Running, and
the log line quietly reads `flags: --mode=stream --level=debug`. Kustomize
does not warn you, because it did precisely what a scalar-list merge means.

Same reasoning if the task had been "add one more flag": a strategic merge
still needs the complete list, while JSON 6902 does it in one op with
`/args/-`. When the only change is *append to a scalar list*, JSON 6902 is
the shorter answer.
