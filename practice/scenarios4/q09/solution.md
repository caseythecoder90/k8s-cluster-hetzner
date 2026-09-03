# Q9 solution

```bash
cd /course4/9/app
cat kustomization.yaml
kubectl kustomize .                 # render only — see what you're about to apply
```

Add the namespace transformer to `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: topaz
resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
```

Then render, apply, count:

```bash
kubectl kustomize . > /course4/9/rendered.yaml
kubectl apply -k .
kubectl kustomize . | grep -c "^kind:"          # 3
echo 3 > /course4/9/count
k -n topaz get all,cm
```

## The three commands

| Command | Does |
|---|---|
| `kubectl kustomize <dir>` | render to stdout, touch nothing |
| `kubectl apply -k <dir>` | render + apply |
| `kubectl delete -k <dir>` | render + delete |

All three take the **directory** containing `kustomization.yaml`, never the
file. Render first, apply second — it's the cheapest way to catch a mistake.

## Traps

- `kubectl apply -f /course4/9/app` is not the same thing: `-f` applies raw
  files and trips over `kustomization.yaml` ("no matches for kind
  Kustomization"). Kustomize needs `-k`.
- `kubectl apply -k . -n topaz` also deploys into topaz, but the task said
  "inside the Kustomization" — the graded artifact is the file, and the
  rendered output must already contain the namespace.
- Order matters for step 2: set the namespace *before* saving the render, or
  the saved file has no namespaces in it.
