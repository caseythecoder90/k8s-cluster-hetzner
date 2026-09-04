# Q13 solution

```bash
k -n lapis get pod                    # ContainerCreating forever
k -n lapis describe pod lapis-app-... | tail -5     # configmap "app-config" not found
cd /course4/13/overlays/prod
ls                                    # app.properties  kustomization.yaml
```

Add the generators to `kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: lapis
resources:
  - ../../base
configMapGenerator:
  - name: app-config
    files:
      - app.properties
    literals:
      - LOG_LEVEL=warn
secretGenerator:
  - name: db-creds
    literals:
      - username=lapis
      - password=ruby-lapis-42
    options:
      disableNameSuffixHash: true
```

```bash
kubectl kustomize .      # ConfigMap app-config-<hash>, Secret db-creds, Deployment pointing at the hash
kubectl apply -k .
k -n lapis get cm,secret,pod
```

## What the hash suffix is for

Generated ConfigMaps get a content hash appended (`app-config-6ck5t9h8f2`),
and Kustomize rewrites every reference to `app-config` in the same build to
the hashed name. Change the file, re-apply: new hash, new name, new
reference, and the Deployment rolls out — that's how a config change becomes
a rollout without touching the Deployment. The base's plain `name: app-config`
is exactly what makes the rewrite work.

An external tool that expects a fixed name is where the suffix hurts, hence
`options.disableNameSuffixHash: true` on the Secret. Setting it under
`generatorOptions:` at the top level would turn the suffix off for every
generator in the file; the task only wanted it for the Secret.

## Generator inputs

| Source | Syntax | Key becomes |
|---|---|---|
| a file | `files: [app.properties]` | the file name |
| a file under another key | `files: [config.txt=app.properties]` | `config.txt` |
| literals | `literals: [LOG_LEVEL=warn]` | `LOG_LEVEL` |
| an env file | `envs: [settings.env]` | one key per `K=V` line |

Same fields for `secretGenerator`; values are base64-encoded for you and
the type defaults to `Opaque`. This mirrors `kubectl create cm --from-file`
/ `--from-literal` / `--from-env-file`, just declaratively.
