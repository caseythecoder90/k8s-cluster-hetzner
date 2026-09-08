# Q7 (topic: `namespaceSelector` and the automatic Namespace label)

`mekong-db` (labels `app=mekong-db`, nginx on container port `80`) runs in
Namespace `mekong`. Three busybox clients want to talk to it, two of them
labelled identically:

| Namespace | Deployment | Pod labels |
|---|---|---|
| `nile` | `nile-client` | `app=nile-client,role=client` |
| `nile` | `nile-batch` | `app=nile-batch,role=batch` |
| `mekong` | `mekong-client` | `app=mekong-client,role=client` |

Only Namespace `nile` is trusted. Write a NetworkPolicy named `allow-from-nile`
in Namespace `mekong` so that:

1. **Any** Pod running in Namespace `nile` may reach the `mekong-db` Pods on
   port `80` — `nile-batch` as much as `nile-client`
2. Nothing else may, including `mekong-client`, whose labels are identical to
   `nile-client`'s
3. Select `nile` by the label Kubernetes puts on every Namespace for you. You
   may not add labels to either Namespace.

Save it as `/course6/7/policy.yaml` and apply it.

> Target: 5 minutes. A `podSelector` inside a `from:` block only ever looks in
> the policy's own Namespace — which is precisely the Namespace you are trying
> to keep out.
