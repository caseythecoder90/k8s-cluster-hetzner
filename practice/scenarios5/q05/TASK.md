# Q5 (topic: deleting things with a strategic merge patch)

Deployment `ledger` comes from `/course5/5/base`. Its Pod cannot schedule:
no node in this cluster has the label the base asks for.

Using a **strategic merge patch** in `/course5/5/overlays/dev` (strategic
merge, not JSON 6902):

1. Remove the annotation `zinc.io/deprecated` — the annotation
   `zinc.io/team` must survive
2. Remove the Pod template's `nodeSelector` entirely

Apply the overlay. The Pod must end up Running. Do not modify the base.

> Target: 4 minutes. Deletion in a strategic merge is never implicit — there
> is exactly one spelling for it.
