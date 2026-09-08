# Q9 solution

## Pass 1 — strategic merge

```yaml
# /course5/9/overlays/prod/patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smelter
spec:
  minReadySeconds: 20                     # Deployment field
  template:
    metadata:
      labels:
        tier: smelting                    # Pod template label
    spec:
      terminationGracePeriodSeconds: 45   # Pod field
```

```yaml
# /course5/9/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: bronze
resources:
  - ../../base
patches:
  - path: patch.yaml
```

The indentation *is* the answer: `minReadySeconds` sits beside `template:`,
`terminationGracePeriodSeconds` sits inside `template.spec`.

## Pass 2 — JSON 6902

```yaml
patches:
  - target:
      kind: Deployment
      name: smelter
    patch: |-
      - op: add
        path: /spec/minReadySeconds
        value: 20
      - op: add
        path: /spec/template/spec/terminationGracePeriodSeconds
        value: 45
      - op: add
        path: /spec/template/metadata/labels/tier
        value: smelting
```

All three are `add`: none of the paths exists in the base. The labels map
under `/spec/template/metadata/labels` **does** exist (`app: smelter`), so
adding a key into it is fine — had it not existed you would have had to add
the map itself.

```bash
kubectl apply -k /course5/9/overlays/prod
kubectl -n bronze rollout status deploy/smelter        # ~20s longer now
kubectl -n bronze get deploy smelter --show-labels
kubectl -n bronze get pod --show-labels
```

## The one hop that decides everything

```
/spec                              ← Deployment: replicas, minReadySeconds,
                                     strategy, revisionHistoryLimit,
                                     progressDeadlineSeconds, selector
/spec/template/metadata/labels     ← the POD's labels
/spec/template/spec                ← Pod: containers, volumes, nodeSelector,
                                     serviceAccountName, restartPolicy,
                                     terminationGracePeriodSeconds
```

A Deployment is a Pod *inside* a template inside a spec. Everything a Pod
knows about sits two levels down.

## The trap: two ways to get it wrong, only one of them noisy

**Noisy.** `add /spec/terminationGracePeriodSeconds` builds without
complaint — JSON 6902 does not know the schema — and then `kubectl apply`
rejects it: `unknown field "spec.terminationGracePeriodSeconds"`. Annoying,
but the cluster tells you.

**Silent, and the one that costs the mark.** `labels` exists at *both*
levels. Write

```yaml
- op: add
  path: /metadata/labels/tier          # the DEPLOYMENT's own labels
  value: smelting
```

and the build renders, the apply succeeds, the rollout is green — and the
Pods do not carry the label. Nothing anywhere reports an error, because you
asked for a legal change to the wrong object. The same shape bites with
`metadata.annotations` and, in a strategic merge, with a `template:` block
you accidentally indented one level too shallow.

So the check is always the Pod, never the Deployment:

```bash
kubectl -n bronze get pod --show-labels
```

Two more that live at the Deployment level and are commonly patched one hop
too deep: `replicas` and `strategy`. And `revisionHistoryLimit` — if a task
says "keep only 2 old ReplicaSets", that is `/spec/revisionHistoryLimit`.
