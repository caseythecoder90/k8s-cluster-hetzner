# Q10 solution

```bash
k -n hera get pods                       # CrashLoopBackOff
k -n hera describe pod <pod-name>         # Events: "exec: no such file or directory"
k -n hera logs <pod-name> --previous      # confirm — may be empty if it never started
```

The `command` overrides the image's entrypoint with a binary path that
doesn't exist in `busybox` — that's the root cause.

```bash
k -n hera set image deploy/hera-worker worker=busybox:1   # no-op, image was already right
k -n hera patch deploy hera-worker --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/command","value":["sleep","3600"]}]'
```

(Or `k -n hera edit deploy hera-worker` and rewrite the `command:` line by
hand — equally valid, just slower.)

```bash
echo "container command pointed at a nonexistent binary; overrode command to sleep 3600" \
  > /course2/10/root-cause.txt
k -n hera get pods
```

The debugging sequence — `get pods` (what's wrong) → `describe pod` (why,
in Events) → `logs --previous` (crashed container's own output) — is the
same three-step reflex for almost every "investigate and fix" question,
regardless of what actually turns out to be broken.
