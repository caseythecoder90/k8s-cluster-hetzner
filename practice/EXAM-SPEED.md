# CKAD speed playbook

Time, not knowledge, is what most people fail on. This is the decision tree
for "how do I change this thing" plus the commands worth memorizing cold.

## Shell setup (already in your lab; the exam gives you the same)

```bash
alias k=kubectl
source <(kubectl completion bash); complete -o default -F __start_kubectl k
export do="--dry-run=client -o yaml"
export now="--force --grace-period=0"
```

Also set your namespace once instead of typing `-n` every command when a
question has many parts in one namespace:

```bash
k config set-context --current --namespace=neptune
```

## How to change an existing resource — in order of speed

**1. Is there a `kubectl set` subcommand?** (~5s, memorize these five)

```bash
k set image deploy/x nginx=nginx:1.31-alpine
k set env deploy/x APP_VERSION=2          # also triggers a rollout
k set resources deploy/x --requests=memory=20Mi --limits=memory=50Mi
k set serviceaccount deploy/x my-sa       # the serviceAccountName trap, solved
k set selector svc/x 'app=web,version=blue'   # blue-green switch
```

**2. Know the exact field path? `kubectl patch`** (~15s)

```bash
k patch deploy cassini -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":2,"maxUnavailable":0}}}}'
k patch svc web-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"targetPort":80,"nodePort":30100}]}}'
```

**3. Otherwise `kubectl edit`** (~30s) — no syntax to recall, any field.
If you make a YAML error, kubectl saves your attempt to a temp file and
prints the path. Nothing is lost.

**4. Export → edit → apply** (~60s) — only when required:
- the task says "save the YAML to /course/..." (the file itself is graded)
- the field is **immutable** (Deployment `selector`, most of a Job spec) and
  needs delete + recreate: `k delete -f f.yaml && k apply -f f.yaml`

## Creating from scratch: always generate, never type

```bash
k run pod-name --image=nginx $do > p.yaml
k create deploy x --image=nginx --replicas=3 $do > d.yaml
k create job x --image=busybox:1 $do -- sh -c "sleep 2 && echo done" > j.yaml
k create cronjob x --image=busybox:1 --schedule="*/1 * * * *" $do -- sh -c "date"
k expose deploy x --name=svc --port=9999 --target-port=80
k create cm my-cm --from-file=index.html=/path/file.html
k create secret generic s --from-literal=key=value
k create ingress ing --class=nginx --rule="/app1=app1-svc:80" --rule="/app2=app2-svc:80"
k create sa my-sa
k create quota my-q --hard=cpu=1,memory=1G,pods=2
```

Anything with no generator (StorageClass, PV, PVC, NetworkPolicy) — copy the
skeleton from kubernetes.io docs, which you're allowed to have open.

## Finding fields without leaving the terminal

```bash
k explain deploy.spec.strategy.rollingUpdate
k explain pod.spec.containers.securityContext --recursive | head -40
```

Faster than searching docs when you know the resource but not the field name.

## Wording → field translations the exam reuses

| Question says | You write |
|---|---|
| "up to N additional Pods above desired" | `maxSurge: N` |
| "no Pod may be unavailable" | `maxUnavailable: 0` |
| "only runs during start of the container" | `startupProbe` |
| "checks it can receive traffic" | `readinessProbe` |
| "restart it if unhealthy" | `livenessProbe` |
| "initially wait X, then every Y" | `initialDelaySeconds: X`, `periodSeconds: Y` |
| "only pull if not already on the node" | `imagePullPolicy: IfNotPresent` |
| "never pull the image" | `imagePullPolicy: Never` |
| "N seconds to shut down gracefully" | `terminationGracePeriodSeconds: N` |
| "N completions, M in parallel" | `completions: N`, `parallelism: M` |
| "run under ServiceAccount X" | `serviceAccountName: X` (**pod** spec) |
| "reachable on port P" (no path given) | `tcpSocket: {port: P}` |

## Traps that cost real points

- `serviceAccountName` lives in `spec.template.spec` (pod), never on the
  container or the Deployment spec.
- `securityContext` exists at BOTH pod and container level — read which the
  question wants. "Container SecurityContext" means the container one.
- Commands with shell syntax (`&&`, `>`, `|`) must run through a shell:
  `-- sh -c "sleep 2 && echo done"`.
- `k logs --previous` for a container that already crashed.
- ConfigMap from file: `--from-file=index.html=/path/x.html` sets the KEY.
  Without `key=`, the key becomes the filename.
- `pathType` is required on every Ingress path in networking.k8s.io/v1.
- StorageClass puts `provisioner`/`reclaimPolicy` at the TOP level, not
  under `spec`.
- When a task says save AND apply, do both — graders check both.
- Check the namespace on every single command. Wrong-namespace answers score
  zero even when the YAML is perfect.

## Triage strategy

killer.sh is deliberately harder than the real exam and ~22 questions in
120 min. Do a first pass answering everything you can do in under 4 minutes,
flag the rest, then return. A question half-done scores partial credit — an
unread question scores nothing.
