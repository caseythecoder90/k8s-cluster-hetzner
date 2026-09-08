# Q12 solution

```bash
k -n gallium get pod                                   # ContainerCreating forever
k -n gallium describe pod renderer-... | tail -5       # configmap "gallium-config" not found
cd /course5/12/overlays/prod
ls -R                                                  # app.properties  runtime.env  content/landing.html
```

```yaml
# /course5/12/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: gallium

resources:
  - ../../base

configMapGenerator:
  - name: gallium-config
    files:
      - app.properties                     # key = the file's own name
      - index.html=content/landing.html    # key = index.html
    literals:
      - LOG_LEVEL=warn
    envs:
      - runtime.env                        # one key per KEY=VALUE line
```

```bash
kubectl kustomize .          # read it: ConfigMap gallium-config-<hash>, and the
                             # Deployment's volume + configMapKeyRef both point at it
kubectl apply -k .
k -n gallium get cm,pod
```

Rendered, that is:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gallium-config-97tt64gtkf
data:
  CACHE_TTL: "300"
  LOG_LEVEL: warn
  MAX_CONNECTIONS: "64"
  app.properties: |
    color=teal
    mode=prod
  index.html: |
    <h1>Gallium</h1>
```

## The four input forms — this is the whole question

| Field | Written as | Key becomes | Value becomes |
|---|---|---|---|
| `files:` | `app.properties` | the file name | the **whole file** |
| `files:` | `index.html=content/landing.html` | `index.html` | the whole file |
| `literals:` | `LOG_LEVEL=warn` | `LOG_LEVEL` | `warn` |
| `envs:` | `runtime.env` | one key **per line** | that line's value |

`secretGenerator` takes exactly the same four fields; it just base64-encodes
the values and defaults `type:` to `Opaque`.

Two rules that go with them:

- **Paths are relative to the kustomization that declares the generator.** The
  overlay's kustomization lives in `overlays/prod`, so `content/landing.html`
  resolves to `overlays/prod/content/landing.html`. A path that climbs out of
  the kustomization's own directory (`../secrets/db.env`, or an absolute
  `/tmp/page.html`) is refused by the loader — copy the file in instead.
- **The key=path form is `key=path`, not `path=key`.** The new key is on the
  left, exactly like `kubectl create cm --from-file=index.html=landing.html`.

## The trap

`files:` and `envs:` both take a file name, and the difference is not
cosmetic:

```yaml
files:
  - runtime.env          # ONE key called "runtime.env" holding both lines
envs:
  - runtime.env          # TWO keys, MAX_CONNECTIONS and CACHE_TTL
```

The base does `configMapKeyRef: {key: MAX_CONNECTIONS}`, so the `files:`
version renders and applies happily and then the Pod dies with
`CreateContainerConfigError — couldn't find key MAX_CONNECTIONS`. Nothing
warns you at build time. If a task talks about environment variables or shows
you a `KEY=VALUE` file, it is `envs:`.

## Why the name is never typed twice

The base says `name: gallium-config` in both the volume and the
`configMapKeyRef`. The generator appends a content hash, and the
nameReference transformer rewrites **every** reference in the same build —
`configMapRef`, `secretKeyRef`, `envFrom`, `volumes[].configMap.name`,
`volumes[].secret.secretName`. Change `app.properties` and re-apply: new
content, new hash, new name, references follow, and the Deployment rolls out
because its Pod template changed. That free rolling restart is the entire
reason the hash exists.
