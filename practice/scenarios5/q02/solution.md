# Q2 solution

```yaml
# /course5/2/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: silver
namePrefix: sv-

resources:
  - ../../base

replicas:
  - name: api        # the BASE name — namePrefix has not been applied yet
    count: 3
  - name: cache
    count: 2

images:
  - name: nginx      # the IMAGE name, not the container name ("main")
    newTag: "1.27-alpine"
  - name: redis-oss  # replacing the repository needs newName + newTag
    newName: redis
    newTag: "7.2-alpine"
```

```bash
kubectl apply -k /course5/2/overlays/prod
```

## The two traps, which are the whole question

1. **`replicas[].name` is the base name.** Transformers run in a defined
   order and `namePrefix` has not been applied when `replicas:` is matched.
   Writing `name: sv-api` matches nothing — and kustomize does **not** error,
   it silently leaves the replica count alone. Same rule for a patch's
   `metadata.name` and a JSON 6902 `target.name`.
2. **`images[].name` is the image, not the container.** The container here is
   called `main` and `store`; the images are `nginx` and `redis-oss`. Matching is
   on the image's repository part, so one entry rewrites that image wherever
   it appears, in any container of any resource.

`newTag` alone changes only the tag; swapping to a different image needs
`newName` as well. There is also `newName` with a digest via `digest:`, which
the exam does not ask for.

## Why no patch

Both changes have first-class fields. A patch would work, but it is three
times the typing under time pressure, and `replicas:`/`images:` are exactly
what an examiner is looking to see you reach for.
