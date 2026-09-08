# Q15 (topic: reading Kustomize build errors)

A colleague left the staging overlay for team Cadmium in this state:

```
$ kubectl kustomize /course5/15/overlays/staging
error: invalid Kustomization: json: unknown field "configmapGenerator"
```

There are **three** independent faults in
`/course5/15/overlays/staging/kustomization.yaml`, and Kustomize will only
ever show you one at a time. Nothing is deployed yet.

Fix the overlay so that `kubectl apply -k /course5/15/overlays/staging`
produces, in Namespace `cadmium`:

1. Deployment `stg-pigment`, `2` replicas, all Ready
2. Service `stg-pigment`
3. A generated ConfigMap holding the key `app.conf` with the contents of
   `/course5/15/overlays/staging/app.conf`, mounted by the Deployment at
   `/etc/pigment`

Every fix belongs in the overlay's `kustomization.yaml`. Do not modify
anything in `/course5/15/base`, and do not rename, move or create any file on
disk — what is on disk is correct.

> Target: 6 minutes. Fix one, re-render, read the next. The order the errors
> come out in is itself the lesson: Kustomize checks the kustomization's own
> field names before it ever looks at a path.
