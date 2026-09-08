# Q10 solution

Read the real list first. Indexes are **build-time positions**, and the only
way to know them is to look:

```bash
kubectl kustomize /course5/10/overlays/prod | grep -n "  - name:"
# app is 0, log is 1
```

```yaml
# /course5/10/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: pewter
resources:
  - ../../base
patches:
  - target:
      kind: Deployment
      name: foundry
    patch: |-
      - op: replace                                        # 1. edit app IN PLACE
        path: /spec/template/spec/containers/0/image
        value: nginx:1.27-alpine
      - op: add                                            # 2. APPEND metrics
        path: /spec/template/spec/containers/-
        value:
          name: metrics
          image: busybox:1
          command: ["sh", "-c", "sleep 86400"]
      - op: add                                            # 3. INSERT proxy at the front
        path: /spec/template/spec/containers/0
        value:
          name: proxy
          image: busybox:1
          command: ["sh", "-c", "sleep 86400"]
```

```bash
kubectl apply -k /course5/10/overlays/prod
kubectl -n pewter get deploy foundry -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'
# proxy app log metrics
kubectl -n pewter get pods            # 4/4
```

## The three list moves

| Last segment of the path | Meaning |
|---|---|
| `/-` | the slot **after** the last element → append |
| `/0`, `/1` | that index |

| op + path | Effect |
|---|---|
| `add /containers/-` | append |
| `add /containers/0` | **insert** at 0, everything shifts down one |
| `replace /containers/0` | swap the **entire** element |
| `replace /containers/0/image` | change **one field** of that element |
| `remove /containers/1` | drop that element, everything after shifts up |

## Trap 1 — `add` on a list index inserts, it does not overwrite

On a **map**, `add` creates-or-overwrites. On a **list**, `add /containers/0`
means "make room at position 0". Nothing is overwritten and the list grows.
If you actually want to replace what is at position 0, the op is `replace`.
This is the single biggest difference between how `add` behaves on the two
kinds of container, and it is why this task's order check exists.

## Trap 2 — `replace /containers/1` wipes the whole container

To change the image of `app` you must point the path **into** the element:

```yaml
- op: replace
  path: /spec/template/spec/containers/0/image     # ✓ one field
  value: nginx:1.27-alpine
```

```yaml
- op: replace
  path: /spec/template/spec/containers/0           # ✗ the whole element
  value: {name: app, image: nginx:1.27-alpine}     #   ports and resources GONE
```

The second version applies cleanly and quietly drops `ports` and
`resources` — the verify script checks for exactly this.

## Trap 3 — the ops run in sequence, and the indexes move under you

Each op sees the document as the previous op left it. In the solution above
the image edit is done **first**, while `app` is still at index 0. Do it the
other way round and `app` is at index 1 by then:

```yaml
      - op: add                                          # proxy inserted first
        path: /spec/template/spec/containers/0
        value: {name: proxy, image: busybox:1, command: ["sh", "-c", "sleep 86400"]}
      - op: replace
        path: /spec/template/spec/containers/1/image     # app is now 1, not 0
        value: nginx:1.27-alpine
```

Both orderings are correct — what is fatal is writing the second one with
`/containers/0/image`, which silently retags the brand-new `proxy` container
to `nginx:1.27-alpine` and leaves `app` on the old image. The build
succeeds, the Pod runs, and the answer is wrong.

The `add /-` append is the one op that is immune: it never needs an index at
all. When a task is "add another container / env var / volume", reach for
`/-`.

## Why not strategic merge

Strategic merge matches `containers` by `name`, so it can add and edit
without counting — but it gives you **no control over order**: new elements
are appended, and there is no way to say "put this one first". The moment a
task pins the order of a list, JSON 6902 is the only strategy that can do it.
