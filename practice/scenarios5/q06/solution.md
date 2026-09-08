# Q6 solution

```bash
cd /course5/6/overlays/prod
vim patch.yaml
```

```yaml
# /course5/6/overlays/prod/patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: solder                 # the BASE name — self-identifying, no target:
spec:
  template:
    spec:
      containers:
        - name: web            # 1. EDIT — match by merge key, name only the change
          image: nginx:1.27-alpine
        - name: shipper        # 2. ADD — a name not in the base is appended
          image: busybox:1
          command: ["sh", "-c", "sleep 86400"]
        - name: legacy         # 3. DELETE — merge key + the directive
          $patch: delete
```

```yaml
# /course5/6/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: tin
resources:
  - ../../base
patches:
  - path: patch.yaml
```

```bash
kubectl kustomize .                       # read the container list BEFORE applying
kubectl kustomize . | grep -n "name:"
kubectl apply -k .
kubectl -n tin get pods                   # 3/3
```

## What is being drilled

`containers` is a list, but Kubernetes tags it *merge by `name`*. That one
fact drives all three moves, and they can all live in the same patch:

| Move | Spelling |
|---|---|
| edit an element | `- name: web` + only the fields that change |
| add an element | `- name: shipper` + the full container |
| delete an element | `- name: legacy` + `$patch: delete` |

The same merge key (`name`) applies to `initContainers`, `env`, `volumes`,
`ports` and `volumeMounts`.

Because the match is by name, `web` keeps its `ports` and `resources` — you
named `image` and nothing else, so nothing else moved. And because the patch
is a *fragment*, `cache` never appears in it at all and survives untouched.

## The trap

**Omitting a container does not delete it.** A strategic merge is additive:
leaving `legacy` out of the patch leaves `legacy` running. Deletion is always
an explicit directive, and there are exactly two spellings:

| Target | Directive |
|---|---|
| a key in a map | `key: null` |
| an element of a keyed list | the merge key + `$patch: delete` |

`$patch: delete` needs the merge key beside it — `- $patch: delete` on its
own matches nothing. And note it is *not* `name: legacy` + `null`; `null`
only deletes map keys.

## Why not JSON 6902 here

You could do it — `replace /spec/template/spec/containers/0/image`,
`add /spec/template/spec/containers/-`, `remove
/spec/template/spec/containers/2` — but every op is an **index**, the
indexes shift as the ops run, and the remove has to be written against the
list as it stands at that moment. Strategic merge matches by name and never
cares about position. When the change is "these containers, by name", it is
the faster and safer strategy.
