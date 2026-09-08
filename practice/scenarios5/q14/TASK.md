# Q14 (topic: overriding a base's generator — `behavior: merge` vs `replace`)

The **base** at `/course5/14/base` declares both of Deployment `catalog`'s
ConfigMaps itself, with `configMapGenerator`:

    app-settings   LOG_LEVEL=info   REGION=eu-west   TIMEOUT=30
    feature-flags  beta_ui=false    dark_mode=false  new_billing=false

`catalog` is running in Namespace `osmium` from the overlay
`/course5/14/overlays/prod` with exactly those values. Change them from the
overlay so that after `kubectl apply -k`:

1. `app-settings` holds `LOG_LEVEL=debug`, a new key `TRACE_SAMPLING=0.5`,
   and still holds `REGION=eu-west` and `TIMEOUT=30`
2. `feature-flags` holds `beta_ui=true` and `dark_mode=true` and **nothing
   else** — `new_billing` must be gone from the ConfigMap entirely
3. `catalog` is still Ready, and both of its `envFrom` references point at
   the ConfigMaps you produced

Do not modify the base. Your overlay must not restate a value the base
already has right: the strings `REGION` and `TIMEOUT` must not appear
anywhere in `/course5/14/overlays/prod`.

> Target: 6 minutes. The two generators need the same one-word field set to
> two different values — and the wrong value on the first one silently drops
> two keys.
