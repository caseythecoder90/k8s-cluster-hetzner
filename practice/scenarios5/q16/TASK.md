# Q16 (topic: build a whole overlay from blank — capstone)

`/course5/16/base` holds Deployment `gauge` (container `web`, image
`nginx:1-alpine`, one env var `MODE=gauge`, and a volume mounting a ConfigMap
`gauge-config` that does not exist yet) and Service `gauge`.

`/course5/16/overlays/prod` is **empty**. Build the whole overlay there, on
top of the base, so that a single `kubectl apply -k` produces all of this:

1. Everything lands in Namespace `mercury` (exists)
2. Every resource name is prefixed with `hg-`
3. Deployment `gauge` runs `3` replicas
4. The `nginx` image is used at tag `1.27-alpine`
5. Every resource carries the label `env: prod` — **without** any selector
   changing
6. ConfigMap `gauge-config` is generated from the literals `UNITS=metric` and
   `SCALE=celsius`; the Deployment's volume must end up pointing at the
   generated object without you typing its name
7. Using a **patch**, container `web` gets a second environment variable
   `READ_ONLY` with the value `true`, and keeps `MODE=gauge`

Apply it. All 3 Pods must be Ready. Do not modify the base.

> Target: 10 minutes. Three different fields in this overlay take the name a
> resource has in the **base**, not the name it will have once the prefix is
> applied.

> **Second pass — do this question twice.** Solve it first with a **strategic
> merge** patch for deliverable 7 and run `verify.sh`. Then delete your patch
> and produce the same result with a **JSON 6902** patch, and verify again.
> `verify.sh` checks the outcome, not the mechanism, so both passes come back
> green.
>
> Target: 10 minutes for the first pass. On the second only the patch changes
> — 2 minutes.
