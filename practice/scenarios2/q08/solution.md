# Q8 solution

```bash
k -n hades edit deploy hades-cache
```

```yaml
        readinessProbe:
          exec:
            command: ["sh", "-c", "test -f /tmp/ready"]
          periodSeconds: 5
          failureThreshold: 3
```

```bash
k -n hades get pods -w                       # READY flips 0/1 -> 1/1 after warm-up
k -n hades get endpointslices -l kubernetes.io/service-name=hades-cache-svc
```

`exec` handlers run a command inside the container; exit code 0 = pass,
anything else = fail. `test -f <path>` is the idiomatic "does this file
exist" check, exit 0 if yes.

Contrast with Q8 in Exam Set 1 (`../scenarios/q08`), which used
`startupProbe` — that one gates liveness/readiness until boot finishes.
**Readiness** here does something different: it doesn't affect restarts at
all, it only controls whether the Service **routes traffic** to the pod. A
not-ready pod stays Running, just invisible to the Service's endpoints —
exactly why the endpoint check above matters as proof, not just the READY
column.
