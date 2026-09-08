# Q2 (topic: the `replicas:` and `images:` transformers)

Overlay `/course5/2/overlays/prod` already sets the Namespace and a name
prefix. Extend it so that, on top of the base:

1. Deployment `api` runs `3` replicas
2. Deployment `cache` runs `2` replicas
3. The `nginx` image is used at tag `1.27-alpine`
4. The `redis-oss` image is wrong — no such repository exists, which is why
   `cache` never starts. Point it at `redis` at tag `7.2-alpine`

Apply the overlay. Every Pod must end up Running. Do not modify the base, and
**do not use a patch of any kind** — every change here has a dedicated
`kustomization.yaml` field.

> Target: 4 minutes. Two of these four take a name you have to think about
> twice: neither is the name you can see in the running cluster.
