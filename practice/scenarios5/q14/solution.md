# Q14 solution

```bash
cat /course5/14/base/kustomization.yaml       # the generators are in the BASE
kubectl kustomize /course5/14/overlays/prod   # read what it renders today
```

```yaml
# /course5/14/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: osmium

resources:
  - ../../base

configMapGenerator:
  - name: app-settings          # same name as in the base — that is the match key
    behavior: merge             # keep the base's keys, add/override mine
    literals:
      - LOG_LEVEL=debug
      - TRACE_SAMPLING=0.5

  - name: feature-flags
    behavior: replace           # throw the base's set away, mine is the whole thing
    literals:
      - beta_ui=true
      - dark_mode=true
```

```bash
kubectl kustomize /course5/14/overlays/prod | grep -A8 'kind: ConfigMap'
kubectl apply -k /course5/14/overlays/prod
k -n osmium get cm
k -n osmium exec deploy/catalog -- env | sort | grep -E 'LOG_LEVEL|REGION|TIMEOUT|TRACE|beta|dark|billing'
```

Rendered:

```yaml
data:                          # app-settings — 4 keys
  LOG_LEVEL: debug             #   overridden
  REGION: eu-west              #   inherited
  TIMEOUT: "30"                #   inherited
  TRACE_SAMPLING: "0.5"        #   added
---
data:                          # feature-flags — 2 keys, new_billing is gone
  beta_ui: "true"
  dark_mode: "true"
```

## The three values of `behavior:`

| Value | Base declares it? | Result |
|---|---|---|
| `create` (default) | no | a new generated object |
| `merge` | **yes** | base's keys, then yours added / overwritten on top |
| `replace` | **yes** | your keys only; the base's set is discarded |

`behavior:` is **only** legal when you are overriding a generator the base
already declares. Put it on a name the base has never heard of and the build
fails:

```
merging from generator ...: id ...ConfigMap.v1/nothing.[noNs] does not exist; cannot merge or replace
```

And the mirror image — declaring `app-settings` in the overlay with **no**
`behavior:` at all — fails too:

```
may not add ConfigMap resource with an already registered id: ConfigMap.v1.[noGrp]/app-settings.[noNs]
```

That second error is the one you will actually hit on the exam, and it means
exactly one thing: add `behavior:`.

## Merge cannot delete

`merge` is additive, like a strategic merge patch: a key you do not mention
keeps the base's value, and there is no `null` trick for generator literals —
writing `new_billing=` gives you an empty string, not a missing key. So:

- "override this value / add this key, leave the rest" → `merge`
- "the ConfigMap must contain exactly these keys" / "remove this key"
  → `replace`

`replace` also gets you the right answer for part 1 if you retype `REGION`
and `TIMEOUT` — which is why the task forbids it. On the exam nobody stops
you, but the base owns those values for a reason: the day someone changes
`REGION` in the base, a `merge` overlay follows and a `replace` overlay
silently keeps serving the stale copy.

## The hash still moves

Both generated names carry a content hash, and both of `catalog`'s `envFrom`
references are rewritten to the new hashes, so this config change rolls the
Deployment out by itself. The base declares the generators, the overlay bends
them, and the Deployment never mentions a hash at all. Everything here works
the same for `secretGenerator`.
