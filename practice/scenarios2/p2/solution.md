# Preview Q2 solution

```bash
mkdir -p /course2/p2/overlay/prod
vim /course2/p2/overlay/prod/kustomization.yaml
```

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: nike
resources:
  - ../../base
replicas:
  - name: nike-web
    count: 3
labels:
  - includeSelectors: false
    pairs:
      env: production
images:
  - name: nginx
    newTag: 1.27-alpine
```

Preview before applying — this catches mistakes for free, no cluster call
needed:

```bash
kubectl kustomize /course2/p2/overlay/prod
```

```bash
kubectl apply -k /course2/p2/overlay/prod
kubectl -n nike get deploy nike-web -o wide
```

Three separate Kustomize concepts, one per requirement — worth keeping
distinct in your head since each has its own top-level key:

- **`replicas:`** — patches a named workload's replica count. (Older
  kustomize versions only supported this via a full strategic-merge `patches:`
  entry — the dedicated `replicas:` key is the current shorthand.)
- **`labels:`** — a transformer that stamps the given key/value onto
  **every** resource's metadata, not just the Deployment. `includeSelectors:
  false` means "don't also inject this label into matchLabels/selectors" —
  leave it false unless the question explicitly wants the label to affect
  selection too (it usually doesn't, and getting this wrong can break a
  Service's selector against its Pods).
- **`images:`** — rewrites image references cluster-wide by matching the
  image *name* (`nginx`) and replacing the tag, without you needing to know
  or repeat the full `image:` line from the base.

Trap: `namespace:` in the overlay is what actually places these resources
into `nike` if the base doesn't declare one — check the base first
(`cat ../base/kustomization.yaml`) rather than assuming.
