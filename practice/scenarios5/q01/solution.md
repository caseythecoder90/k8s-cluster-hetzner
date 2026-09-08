# Q1 solution

```bash
mkdir -p /course5/1/overlays/prod
cd /course5/1/overlays/prod
vim kustomization.yaml
```

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: copper
namePrefix: pr-
nameSuffix: -v2
commonAnnotations:
  owner: copper

resources:
  - ../../base
```

```bash
kubectl kustomize /course5/1/overlays/prod > /course5/1/rendered.yaml   # step 5
kubectl apply -k /course5/1/overlays/prod                              # step 6
```

## What is being drilled

- `-k` takes a **directory**, and it points at the **overlay**, never the base.
- `kubectl kustomize <dir>` renders to stdout and touches nothing; `apply -k`
  renders *and* applies. "Save the rendered manifests" is always the former.
- A base is just a directory listed under `resources:`. There is no `bases:`
  field any more (it still parses, but do not write it).
- `namePrefix` + `nameSuffix` both apply: `web` becomes `pr-web-v2`. The
  Service's selector is *not* renamed, and it does not need to be — the
  Deployment's pod labels are untouched by name transformers.

## Trap

Render **before** you apply, not after. If you apply first and then redirect
`kubectl kustomize` into the file you have still passed, but on the real exam
the order is what saves you: reading the render is how you catch a bad
`kustomization.yaml` before it reaches the cluster.
