# Q11 solution

A strategic merge patch is a **fragment of the real manifest**: the same
shape, only the fields you want to change, plus enough identity for Kustomize
to know which resource it belongs to (`kind` + `metadata.name`).

```bash
cd /course4/11/overlays/prod
vim patch-resources.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: agate-api
spec:
  template:
    spec:
      containers:
        - name: api
          resources:
            requests:
              cpu: 50m
              memory: 32Mi
            limits:
              memory: 64Mi
          readinessProbe:
            httpGet:
              path: /
              port: 80
            periodSeconds: 5
```

Reference it from the kustomization:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: agate
resources:
  - ../../base
replicas:
  - name: agate-api
    count: 2
patches:
  - path: patch-resources.yaml
```

```bash
kubectl kustomize .                 # the rendered Deployment shows the merged container
kubectl apply -k .
k -n agate get deploy agate-api -o yaml | grep -A12 "resources:"
k -n agate get pod                  # 2/2 once the probe passes
```

## Why it merges instead of replacing

`containers` is a list, but Kubernetes marks it as *merge by `name`*. So
`- name: api` finds the existing container and merges the new fields in;
image, ports and everything else survive. Forget `name: api` and Kustomize
has nothing to match on (it errors). Under `resources.requests` the base
already had tiny values — those keys are overwritten, which is what we want.

## Fields you don't remember

```bash
k explain deploy.spec.template.spec.containers.readinessProbe.httpGet
k explain deploy.spec.template.spec.containers.resources
```

Or generate a Pod with `k run x --image=nginx $do`, and copy the shape.

## Alternatives that also pass

- Inline patch: `patches: - patch: |-` followed by the same YAML, indented.
  Fine for two lines; a separate file is easier to edit for this much.
- Legacy field `patchesStrategicMerge: [patch-resources.yaml]` still works
  but is deprecated — use `patches:`.
