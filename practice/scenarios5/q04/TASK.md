# Q4 (topic: patching a map — both strategies)

Overlay `/course5/4/overlays/dev` already points at the base. Using a patch
in that overlay, change Deployment `worker` so that:

1. Container `app` gets a memory **limit** of `256Mi` (it has requests only)
2. The Deployment carries the annotation `maintainer: nickel-team`

Apply the overlay. Do not modify the base.

> **Second pass — do this question twice.** Solve it first with a **strategic
> merge** patch and run `verify.sh`. Then delete your patch and produce the
> exact same result with a **JSON 6902** patch, and verify again. `verify.sh`
> checks the outcome, not the mechanism, so both passes should come back
> green. The second pass is where the JSON 6902 gotcha lives.
>
> Target: 4 minutes per pass.
