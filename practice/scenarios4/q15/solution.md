# Q15 solution

## 1. Tear down dev with Kustomize

```bash
kubectl kustomize /course4/15/overlays/dev      # see exactly what will go
kubectl delete -k /course4/15/overlays/dev
k -n amethyst-dev get all                       # empty; the Namespace stays
```

`delete -k` renders the same manifests `apply -k` did and deletes those
objects — nothing more. Deleting the Namespace would also work but destroys
things the overlay never created (and the task forbade it).

## 2. Prod overlay

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: amethyst
resources:
  - ../../base
images:
  - name: nginx
    newTag: 1.27-alpine
  - name: redis
    newTag: 7.2-alpine
replicas:
  - name: web
    count: 3
  - name: cache
    count: 1
```

```bash
kubectl kustomize /course4/15/overlays/prod | grep -E "image:|replicas:"
kubectl apply -k /course4/15/overlays/prod
k -n amethyst get deploy -o wide
```

## The two transformers

**`images:`** matches by the image *name* as written in the manifest
(`nginx`, `redis` — the part before the tag), across every container in
every resource. `newTag` changes the tag, `newName` the repository, `digest`
pins a digest. "Replace `nginx` by `nginx:1.27-alpine`" is a tag change, so
`newTag` is enough; `newName: nginx` would be redundant but harmless.

**`replicas:`** matches by resource name and sets `spec.replicas`, on
Deployments, ReplicaSets, StatefulSets and ReplicationControllers.

Both are declarative shorthand for what a patch could also do — and when the
task names the field, the grader can check the field.

## Trap: `apply -k` never prunes

Removing a resource from a kustomization and re-applying leaves the old
object running in the cluster. Cleaning up is always explicit: `delete -k`
(everything the overlay renders) or `kubectl delete` on the individual
object. This is why set 3's canary question said "scale to 0, don't delete
from the kustomization".
