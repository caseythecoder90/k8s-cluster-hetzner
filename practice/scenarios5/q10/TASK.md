# Q10 (topic: JSON 6902 on a list — index, insert, append)

Deployment `foundry` at `/course5/10/base` runs two containers, `app` then
`log`. The overlay `/course5/10/overlays/prod` already points at the base.

Using a **JSON 6902 patch** in the overlay (JSON 6902 only — no strategic
merge patch file anywhere in the overlay), make the container list end up
**exactly this, in this order**:

| # | name | image | command |
|---|---|---|---|
| 0 | `proxy` | `busybox:1` | `sh -c "sleep 86400"` |
| 1 | `app` | `nginx:1.27-alpine` | — |
| 2 | `log` | `busybox:1` | unchanged |
| 3 | `metrics` | `busybox:1` | `sh -c "sleep 86400"` |

`proxy` and `metrics` are new. `app` changes **only** its image — its
`ports` and `resources` must survive exactly as they are in the base. `log`
is untouched.

Apply the overlay. All four containers must be Ready. Do not modify the base.

```bash
kubectl -n pewter get deploy foundry -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'
```

> Target: 6 minutes. The ops in one patch run in order, one after another,
> against the list as the previous op left it — so the index you need for the
> image edit depends on where you put the insert.
