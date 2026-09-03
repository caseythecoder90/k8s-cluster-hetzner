# Q15 (topic: Kustomize images and replicas, delete -k)

Team Amethyst runs a dev and a prod environment from `/course4/15`.

1. The dev environment (overlay `/course4/15/overlays/dev`, Namespace
   `amethyst-dev`) is no longer needed. Remove everything it deployed
   **using Kustomize** — do not delete the Namespace itself
2. Adjust the prod overlay `/course4/15/overlays/prod` so that:
   - image `nginx` is replaced by `nginx:1.27-alpine` and image `redis` gets
     tag `7.2-alpine` — use the `images` transformer, not patches
   - Deployment `web` runs `3` replicas and Deployment `cache` runs `1` —
     use the `replicas` field, not patches
3. Apply the prod overlay (it targets Namespace `amethyst`, which exists)
