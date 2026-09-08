# Q9 (topic: Deployment level vs Pod level in one patch)

Deployment `smelter` comes from `/course5/9/base`; the overlay
`/course5/9/overlays/prod` already points at it. Team Bronze wants a slower,
safer rollout.

Using **one patch** in the overlay, make all three of these changes:

1. The **Deployment** waits `20` seconds before treating a new Pod as
   available (`minReadySeconds`)
2. The **Pod** gets `45` seconds to shut down (`terminationGracePeriodSeconds`)
3. The **Pod template** carries the label `tier: smelting` — the Deployment's
   own `metadata.labels` must NOT gain it, and no selector may change

Apply the overlay and wait for the rollout. Do not modify the base.

```bash
kubectl -n bronze get deploy smelter --show-labels     # tier must NOT be here
kubectl -n bronze get pod --show-labels                # tier must be here
```

> **Second pass — do this question twice.** Solve it first with a **strategic
> merge** patch and run `verify.sh`. Then delete your patch and produce the
> exact same result with a **JSON 6902** patch, and verify again.
> `verify.sh` checks the outcome, not the mechanism, so both passes come back
> green.
>
> Target: 4 minutes per pass. Every one of the three fields hangs off a
> different depth of the same tree — write the path out loud before you type
> it.
