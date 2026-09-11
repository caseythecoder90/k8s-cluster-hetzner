# q10 solution

`work/q10/pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ckad-q10
spec:
  containers:
    - name: app
      image: ckad-q10:v1
      args: ["--mode=fast"]
      ports:
        - containerPort: 8080
      securityContext:
        runAsUser: 1001
```

`work/q10/answer.txt`:

```
command: ENTRYPOINT
args: CMD
```

## Why

**There is no `command:` in that Pod, and that is the whole point.** The task
said keep the image's entrypoint. `command:` overrides `ENTRYPOINT`, so writing
one — even `command: ["/opt/app/server"]`, which looks harmless — is at best
redundant and at worst wrong the moment the image's entrypoint changes. Omit
the field and the image's own value stands.

`args: ["--mode=fast"]` replaces `CMD ["--mode=slow"]`, giving
`/opt/app/server --mode=fast`.

**The trap in the other direction:** setting `command:` *without* `args:` wipes
the image's `CMD` — Kubernetes does not merge them. A Pod with only
`command: ["/opt/app/server"]` here runs the server with **no arguments**, not
with `--mode=slow`.

**`USER 1001` is not inherited into the Pod spec.** The image would run as 1001
anyway, but the question asked you to declare it, and declaring it is what makes
the Pod's behaviour independent of the image — the same reason
`runAsNonRoot: true` exists as an assertion.

**`EXPOSE` → `containerPort` is documentation on both sides.** Neither one
publishes anything. Traffic reaches the Pod because a Service selects it, or
because something connects to the Pod IP directly. Leaving `containerPort` out
changes nothing at runtime — but a question that says "declare the port" is
graded on it being there.

Generate the skeleton rather than typing it:

```bash
k run ckad-q10 --image=ckad-q10:v1 $do > pod.yaml   # then add args/ports/securityContext
k explain pod.spec.containers.securityContext
```

Validate without a cluster: `kubectl apply --dry-run=client -f pod.yaml`.
