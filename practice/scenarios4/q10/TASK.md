# Q10 (topic: Kustomize overlays and transformers)

Base manifests for the Zircon web app are at `/course4/10/base` on the
control-plane host. Create an overlay at `/course4/10/overlays/staging`
which, on top of the base:

1. Places all resources in Namespace `zircon` (exists)
2. Prefixes every resource name with `stg-`
3. Runs the Deployment with `2` replicas
4. Uses image tag `1.27-alpine` for the `nginx` image
5. Adds the label `env: staging` to every resource — without touching any
   selectors

Apply the overlay. Do not modify the base.
