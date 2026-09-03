# Q7 solution

```bash
k -n poseidon get pod poseidon-web -o yaml > p.yaml
```

(Pods are mostly immutable — adding a container requires delete + recreate,
so export, edit, then `replace --force`.)

```yaml
  containers:
  - name: web
    ...                        # unchanged
  - name: log-shipper
    image: busybox:1
    command: ["sh", "-c", "tail -F /var/log/app/access.log"]
    volumeMounts:
    - name: logs
      mountPath: /var/log/app   # same volume name AND path as the main container
```

```bash
k -n poseidon replace -f p.yaml --force
k -n poseidon logs poseidon-web -c log-shipper -f
```

The concept this tests: a **sidecar** shares the Pod's network and volumes
and runs for the Pod's entire lifetime, alongside the main container — unlike
an initContainer, which runs to completion *before* anything else starts.
Both are declared under `containers:`; nothing marks one as "the sidecar" —
it's just a second long-running container that happens to support the first.

`-c <name>` is required on `logs`/`exec` the moment a Pod has more than one
container — omitting it errors with "a container name must be specified."
