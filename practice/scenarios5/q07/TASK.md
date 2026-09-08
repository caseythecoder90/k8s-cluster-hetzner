# Q7 (topic: patching a scalar list — `args:`)

Container `app` of Deployment `refinery` (base at `/course5/7/base`) is
started with a flag list:

```yaml
args:
  - "--mode=batch"
  - "--level=info"
  - "--retries=3"
```

Team Iron is moving the job to streaming. Using a patch in the overlay
`/course5/7/overlays/prod`, make the container's `args` end up **exactly**
this, in this order:

```yaml
args:
  - "--mode=stream"
  - "--level=debug"
  - "--retries=3"
  - "--timeout=60s"
```

The container's `command` must not change. Apply the overlay; the Pod must
be Running. Do not modify the base.

The container echoes its flags every 30 seconds, so you can read the result
two ways:

```bash
kubectl -n iron get deploy refinery -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
kubectl -n iron logs deploy/refinery | tail -1        # flags: ...
```

> **Second pass — do this question twice.** Solve it first with a **strategic
> merge** patch and run `verify.sh`. Then delete your patch and produce the
> exact same result with a **JSON 6902** patch, and verify again.
> `verify.sh` checks the outcome, not the mechanism, so both passes come back
> green.
>
> Target: 4 minutes per pass. One of the four entries is unchanged from the
> base — think hard about whether you still have to write it out.
