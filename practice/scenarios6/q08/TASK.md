# Q8 (topic: AND vs OR in a `from:` block — the dash is the operator)

`oder-api` (labels `app=oder-api`, nginx on container port `80`) runs in
Namespace `oder`. Three busybox clients can currently reach it:

| Namespace | Deployment | Pod labels | Must end up |
|---|---|---|---|
| `rhine` | `rhine-web` | `app=rhine-web,role=web` | **allowed** |
| `rhine` | `rhine-batch` | `app=rhine-batch,role=batch` | **blocked** |
| `oder` | `oder-web` | `app=oder-web,role=web` | **blocked** |

Write a NetworkPolicy named `allow-rhine-web` in Namespace `oder` that lets
**only Pods labelled `role=web` that are running in Namespace `rhine`** reach
the `oder-api` Pods on port `80`.

1. `rhine-batch` is in the right Namespace with the wrong label — it must be
   blocked
2. `oder-web` has the right label in the wrong Namespace — it must be blocked
3. Select `rhine` by the label Kubernetes sets on every Namespace; do not add
   Namespace labels of your own

Save it as `/course6/8/policy.yaml` and apply it.

> Target: 5 minutes. Both selectors go inside the same `from:` block. Whether
> that block means "and" or "or" comes down to one character — and one of the
> two spellings lets both of the Pods above straight in.
