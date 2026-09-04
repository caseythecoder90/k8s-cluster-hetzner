# Q10 solution

```bash
mkdir -p /course4/10/overlays/staging
vim /course4/10/overlays/staging/kustomization.yaml
```

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: zircon
namePrefix: stg-
resources:
  - ../../base
replicas:
  - name: web
    count: 2
images:
  - name: nginx
    newTag: 1.27-alpine
labels:
  - pairs:
      env: staging
```

```bash
kubectl kustomize /course4/10/overlays/staging      # read it before applying
kubectl apply -k /course4/10/overlays/staging
k -n zircon get deploy,svc,ep -o wide
```

One requirement, one top-level field:

| Requirement | Field | Notes |
|---|---|---|
| Namespace | `namespace:` | sets `metadata.namespace` on every resource |
| name prefix | `namePrefix:` | also rewrites references (the Service still finds its Pods via labels, so nothing breaks) |
| replicas | `replicas:` | `name` is the resource's name **in the base** (`web`), not `stg-web` |
| image tag | `images:` | matched by image name (`nginx`), not container name |
| label everywhere | `labels:` | list form; `includeSelectors` defaults to `false` |

The overlay references the base as a **directory** under `resources:` — the
path is relative to the overlay's own directory (`../../base`).

## The selector trap

`commonLabels:` also satisfies "label on every resource", but it injects the
label into `spec.selector` of the Deployment and the Service as well. On a
fresh apply that still works; on a Deployment that already exists it fails
with *field is immutable*. The task said "without touching any selectors",
which is exactly what the newer `labels:` transformer does by default:

```yaml
labels:
  - pairs:
      env: staging
    includeSelectors: false     # the default — shown for clarity
```

## If a field name won't come to mind

`kustomization.yaml` has no `kubectl explain`. The reference page
(kubectl.docs.kubernetes.io → Kustomization) is one search away and lists
every field; the exam permits it. Also: `kubectl kustomize` errors are
specific ("unknown field"), so a typo costs seconds, not minutes.
