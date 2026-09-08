# Q8 (topic: JSON 6902 — picking the right op)

Deployment `plating` lives at `/course5/8/base`; the overlay
`/course5/8/overlays/prod` already points at it. Read the base first —
which fields are already there decides which operation you may use.

Using a **JSON 6902 patch** in the overlay (JSON 6902 only — no strategic
merge patch file anywhere in the overlay), make these three changes:

1. Environment variable `LOG_LEVEL` on container `app` becomes `debug`
2. Container `app` gets `imagePullPolicy: Always`
3. The Deployment's own label `retired` is gone — the label `app: plating`
   must survive

`kubectl kustomize` must render without error, and the container's existing
port, image and resource requests must be untouched. Apply the overlay; the
Pod must be Running. Do not modify the base.

> Target: 5 minutes. Three changes, three different situations — exactly one
> of the three is a path that is not in the base yet, and one operation
> refuses to work on a path that is not there.
