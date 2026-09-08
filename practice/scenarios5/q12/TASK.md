# Q12 (topic: configMapGenerator — the four input forms)

Deployment `renderer` is already applied into Namespace `gallium` from the
overlay `/course5/12/overlays/prod`. Its Pod will not start: it mounts a
ConfigMap `gallium-config` and reads one environment variable out of it, and
that ConfigMap does not exist.

The source data is already sitting in the overlay directory:

    /course5/12/overlays/prod/app.properties
    /course5/12/overlays/prod/content/landing.html
    /course5/12/overlays/prod/runtime.env

Generate `gallium-config` from the overlay's `kustomization.yaml` so that it
ends up holding exactly these keys:

1. `app.properties` — the contents of `app.properties`
2. `index.html` — the contents of `content/landing.html` (note the key is
   **not** the file name)
3. `LOG_LEVEL` — the value `warn`, which is not in any file
4. `MAX_CONNECTIONS` and `CACHE_TTL` — one key per line of `runtime.env`

Apply the overlay. The Pod must end up Running, and the generated name must
never be typed by you — the Deployment's two references to `gallium-config`
are rewritten by the build.

Do not modify the base.

> Target: 6 minutes. Three of the four inputs are files on disk, but they do
> not all belong under the same generator field — one file has to produce two
> keys.
