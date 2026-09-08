# Q13 solution

```bash
k -n indium get pod                                  # both stuck
k -n indium describe pod audit-...  | tail -3        # configmap "broker-rules" not found
k -n indium describe pod broker-... | tail -3        # secret "broker-auth" not found
cd /course5/13/overlays/prod
```

```yaml
# /course5/13/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: indium

resources:
  - ../../base

secretGenerator:
  - name: broker-auth              # hash KEPT — the build rewrites broker's refs
    type: Opaque
    literals:
      - username=indium
      - password=bismuth-77

configMapGenerator:
  - name: broker-rules             # exact name — audit is outside this build
    files:
      - rules.conf
    options:
      disableNameSuffixHash: true
```

```bash
kubectl kustomize .          # Secret broker-auth-<hash>, ConfigMap broker-rules
kubectl apply -k .
k -n indium get secret,cm
k -n indium get deploy
```

## Where `disableNameSuffixHash` goes — the trap

There are two places, and they are not interchangeable:

```yaml
generatorOptions:                    # top level — EVERY generator in this file
  disableNameSuffixHash: true

configMapGenerator:
  - name: broker-rules
    options:                         # per generator — only this one
      disableNameSuffixHash: true
```

The top-level `generatorOptions:` is the one that gets reached for under time
pressure, and here it is wrong: it would strip the Secret's hash too. The
question deliberately wants one of each, so the option has to be scoped to
the generator that needs it. `generatorOptions:` also carries `labels:` and
`annotations:` that get stamped onto every generated object.

## When each is right

**Keep the hash (the default) when the reference lives inside the build.**
The nameReference transformer rewrites `secretKeyRef`, `configMapRef`,
`envFrom`, `volumes[].configMap.name` and `volumes[].secret.secretName` for
every resource in the same build. So:

    change the password  →  new content  →  new hash  →  new Secret name
                         →  broker's env is rewritten  →  Pod template changed
                         →  Deployment rolls out

That is a free, correct rolling restart on every config change, and it is
impossible to get by hand. The old hashed Secret is left behind (`apply -k`
never prunes), which is exactly what makes the rollback trivial.

**Kill the hash when something outside the build says the name.** `audit`
here — but on the exam it is a ServiceAccount's `imagePullSecrets`, an
Ingress' `tls.secretName`, another team's chart, or a task that simply says
*"a ConfigMap named `nginx-conf`"*. Those references are not rewritten,
because the resource holding them is not part of your build. A hashed name
would leave them dangling forever.

Read the wording: **"must be named exactly X"** is the exam's way of saying
`disableNameSuffixHash: true`. Nothing else in Kustomize produces that
phrasing.

## The leftover

If your first apply put the hash on the wrong object, fix the kustomization
and re-apply — then delete the object you orphaned:

```bash
k -n indium get cm,secret          # broker-rules-8kh4t2... still sitting there
k -n indium delete cm broker-rules-8kh4t2f5tc
```

`apply -k` renders and applies; it never deletes what it no longer produces.
`verify.sh` fails on that leftover on purpose.
