# Q11 solution

Write the four pointers out on paper before typing anything:

| Key | Path segment |
|---|---|
| `app.kubernetes.io/managed-by` | `app.kubernetes.io~1managed-by` |
| `nginx.ingress.kubernetes.io/rewrite-target` | `nginx.ingress.kubernetes.io~1rewrite-target` |
| `brass.io/cost~center` | `brass.io~1cost~0center` |
| `app.kubernetes.io/version` | `app.kubernetes.io~1version` |

```yaml
# /course5/11/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: brass
resources:
  - ../../base
patches:
  - target:
      kind: Deployment
      name: bell
    patch: |-
      - op: replace
        path: /metadata/labels/app.kubernetes.io~1managed-by
        value: kustomize
      - op: remove
        path: /metadata/annotations/nginx.ingress.kubernetes.io~1rewrite-target
      - op: remove
        path: /metadata/annotations/brass.io~1cost~0center
      - op: add
        path: /metadata/annotations/app.kubernetes.io~1version
        value: "2.1.0"
```

```bash
kubectl kustomize /course5/11/overlays/prod | head -20   # ALWAYS render first
kubectl apply -k /course5/11/overlays/prod
kubectl -n brass get deploy bell -o jsonpath='{.metadata.annotations}{"\n"}'
```

## The rule

A JSON Pointer is `/`-delimited, so the two characters that mean something
inside a pointer have to be escaped when they appear **in a key**:

| In the key | In the path |
|---|---|
| `~` | `~0` |
| `/` | `~1` |

**Replace `~` first, then `/`.** That order is not decoration:

```
brass.io/cost~center
  ~ first:  brass.io/cost~0center
  / next:   brass.io~1cost~0center        ✓
```

```
brass.io/cost~center
  / first:  brass.io~1cost~center
  ~ next:   brass.io~01cost~0center       ✗  the ~ of ~1 got escaped too
```

Dots, dashes and underscores are **not** special. `app.kubernetes.io` stays
exactly as written — escaping a dot here is a different, equally wrong
pointer.

## Escape in `path:`, never in `value:`

```yaml
- op: add
  path: /metadata/annotations/app.kubernetes.io~1version   # escaped
  value: "2.1.0"
```

```yaml
- op: add
  path: /metadata/annotations                              # the whole map
  value:
    app.kubernetes.io/version: "2.1.0"                     # NOT escaped
```

Both are legal — but the second overwrites the entire annotations map, so it
would take `brass.io/team` with it. Point at the key.

## What going wrong looks like

- Miss the `~1` and the pointer reads as **two** levels:
  `/metadata/annotations/nginx.ingress.kubernetes.io/rewrite-target` means a
  key `rewrite-target` inside a map called `nginx.ingress.kubernetes.io`,
  which does not exist. A `remove` there fails the **whole build** —
  `remove operation does not apply: doc is missing path` — so none of your
  four ops land.
- The same mistake with `add` does not error. It happily creates the nested
  map, and you end up with an annotation whose key really is
  `nginx.ingress.kubernetes.io` and whose value is a map. Renders fine,
  applies fine, wrong. Render and read before applying.

## Two side notes worth keeping

`brass.io/cost~center` is not a legal Kubernetes key in the first place —
the name half of an annotation key may only contain alphanumerics, `-`, `_`
and `.`. So while it is in the manifest, `kubectl apply -k` is rejected by
the API server and *nothing* in the build reaches the cluster. Getting the
`~0` right is what makes the whole apply work.

And the strategy note: a strategic merge patch writes these keys
**verbatim**, no escaping at all —

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: null
```

— which is why, when the exam lets you choose and the key has a `/` in it,
strategic merge is the faster and safer answer. This question forbids it so
that the escaping is drilled; on the day, know both and pick deliberately.
