# Q12 (topic: Kustomize JSON 6902 patch)

Deployment `jasper-worker` is deployed from overlay
`/course4/12/overlays/dev` into Namespace `jasper`. Using a **JSON 6902
patch** in the dev overlay (inline or in a file, but JSON 6902 — not
strategic merge), make these changes to the Deployment:

1. Change the value of the existing environment variable `MODE` (the first
   entry in the container's env list) from `batch` to `stream`
2. Add a second environment variable `DEBUG` with value `true` at the end
   of the env list
3. Remove the annotation `jasper.io/legacy-owner` from the Deployment's
   metadata. The other annotation must stay

Apply the overlay. The base must not change.
