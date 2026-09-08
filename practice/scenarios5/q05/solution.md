# Q5 solution

```yaml
# /course5/5/overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: zinc
resources:
  - ../../base
patches:
  - path: patch.yaml
```

```yaml
# /course5/5/overlays/dev/patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ledger
  annotations:
    zinc.io/deprecated: null      # delete this one key
spec:
  template:
    spec:
      nodeSelector: null          # delete the whole map
```

```bash
kubectl kustomize /course5/5/overlays/dev | grep -A3 annotations   # look first
kubectl apply -k /course5/5/overlays/dev
kubectl -n zinc get pods -w
```

## The rule

**A strategic merge is additive. Omitting a key never deletes it.** Deleting
is always an explicit directive, and there are exactly two:

| Target | Directive |
|---|---|
| a key in a map | `key: null` |
| an element of a keyed list | `- name: x` + `$patch: delete` |

Leaving `zinc.io/deprecated` out of the patch does nothing at all — the base's
value survives untouched. This is the single most common wrong answer on
deletion questions.

## Why the Pod was Pending

`nodeSelector: {disktype: ssd}` and no node carries that label, so the
scheduler has nowhere to put it — `kubectl -n zinc describe pod` says
`0/2 nodes are available: ... didn't match Pod's node affinity/selector`.
Getting the Pod to Running is the proof the deletion actually landed.

## Note on the annotation key

`zinc.io/deprecated` contains a `/`, and in a strategic merge you write it
**verbatim** — no escaping. The `~1` escaping rule belongs to JSON 6902
pointers only. When a task lets you pick the strategy and the key has a slash
in it, strategic merge is the faster, safer choice.
