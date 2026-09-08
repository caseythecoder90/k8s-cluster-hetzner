# Exam Set 5 — all tasks (print/read this during a timed run)

16 questions, Kustomize only, written to every section of
`notes/11-kustomize/13-memorize-cold.md`. This is a **drill, not a mock exam**:
on the real thing Kustomize is maybe one or two questions. Pace at
**~5 min/question**; anything you cannot finish in that time is a section of
the notes to re-read tonight.

There is no standalone `kustomize` binary — `kubectl kustomize`,
`kubectl apply -k`, `kubectl delete -k` and `kubectl diff -k` are what you have,
and every answer is `kustomization.yaml` edited in vim.

**Six of these are meant to be done twice.** Where `TASK.md` carries a *Second
pass* note, `verify.sh` grades the outcome and not the mechanism: solve it with
a strategic merge, verify, delete the patch, redo it with JSON 6902, verify
again. The questions that force one strategy say so, and their `verify.sh`
rejects the other one.

Render before you apply. `kubectl kustomize <dir>` costs three seconds and
catches the mistake before the cluster does.

---

# Q1 (topic: the four commands + the name/namespace transformers)

Base manifests for team Copper are at `/course5/1/base`. Build an overlay at
`/course5/1/overlays/prod` that, on top of the base:

1. Places every resource in Namespace `copper` (exists)
2. Prefixes every resource name with `pr-`
3. Suffixes every resource name with `-v2`
4. Adds the annotation `owner: copper` to every resource

Then:

5. Save the rendered manifests — without applying them — to
   `/course5/1/rendered.yaml`
6. Apply the overlay

Do not modify the base.

> Target: 4 minutes. Everything here is `kustomization.yaml` fields; if you
> reach for a patch you have overshot the question.

---

# Q2 (topic: the `replicas:` and `images:` transformers)

Overlay `/course5/2/overlays/prod` already sets the Namespace and a name
prefix. Extend it so that, on top of the base:

1. Deployment `api` runs `3` replicas
2. Deployment `cache` runs `2` replicas
3. The `nginx` image is used at tag `1.27-alpine`
4. The `redis-oss` image is wrong — no such repository exists, which is why
   `cache` never starts. Point it at `redis` at tag `7.2-alpine`

Apply the overlay. Every Pod must end up Running. Do not modify the base, and
**do not use a patch of any kind** — every change here has a dedicated
`kustomization.yaml` field.

> Target: 4 minutes. Two of these four take a name you have to think about
> twice: neither is the name you can see in the running cluster.

---

# Q3 (topic: labels that do not touch selectors)

The Cobalt portal is already running in Namespace `cobalt`, applied from the
base at `/course5/3/base`.

Compliance wants every resource of this app to carry the label
`tier: frontend`.

1. Create an overlay at `/course5/3/overlays/labelled` on top of the base
2. Add the label `tier: frontend` to every resource — **without changing any
   selector**
3. Apply the overlay against the running app

Do not modify the base. The Deployment must still be Ready when you are done.

> Target: 3 minutes. There are two fields that add labels and only one of them
> can be applied to a live Deployment.

---

# Q4 (topic: patching a map — both strategies)

Overlay `/course5/4/overlays/dev` already points at the base. Using a patch
in that overlay, change Deployment `worker` so that:

1. Container `app` gets a memory **limit** of `256Mi` (it has requests only)
2. The Deployment carries the annotation `maintainer: nickel-team`

Apply the overlay. Do not modify the base.

> **Second pass — do this question twice.** Solve it first with a **strategic
> merge** patch and run `verify.sh`. Then delete your patch and produce the
> exact same result with a **JSON 6902** patch, and verify again. `verify.sh`
> checks the outcome, not the mechanism, so both passes should come back
> green. The second pass is where the JSON 6902 gotcha lives.
>
> Target: 4 minutes per pass.

---

# Q5 (topic: deleting things with a strategic merge patch)

Deployment `ledger` comes from `/course5/5/base`. Its Pod cannot schedule:
no node in this cluster has the label the base asks for.

Using a **strategic merge patch** in `/course5/5/overlays/dev` (strategic
merge, not JSON 6902):

1. Remove the annotation `zinc.io/deprecated` — the annotation
   `zinc.io/team` must survive
2. Remove the Pod template's `nodeSelector` entirely

Apply the overlay. The Pod must end up Running. Do not modify the base.

> Target: 4 minutes. Deletion in a strategic merge is never implicit — there
> is exactly one spelling for it.

---

# Q6 (topic: strategic merge on a keyed list — edit, add, delete)

Deployment `solder` at `/course5/6/base` runs three containers: `web`,
`cache` and `legacy`. Team Tin is retiring the `legacy` container and adding
a log shipper.

Using **one strategic merge patch** (strategic merge, not JSON 6902) in the
overlay `/course5/6/overlays/prod`:

1. Container `web` runs image `nginx:1.27-alpine` — its port and resources
   must survive
2. A new container `shipper` is added: image `busybox:1`, command
   `sh -c "sleep 86400"`
3. Container `legacy` is gone
4. Container `cache` is untouched

Apply the overlay. All three remaining containers must be Ready. Do not
modify the base.

> Target: 5 minutes. All three moves live in the same `containers:` list, and
> the list is matched by one field — but only two of the three moves are
> spelled by simply naming what you want.

---

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

---

# Q8 (topic: JSON 6902 — picking the right op)

Deployment `plating` lives at `/course5/8/base`; the overlay
`/course5/8/overlays/prod` already points at it. Read the base first —
which fields are already there decides which operation you may use.

Using a **JSON 6902 patch** in the overlay (JSON 6902 only — no strategic
merge patch file anywhere in the overlay), make these three changes:

1. Environment variable `LOG_LEVEL` on container `app` becomes `debug`
2. Container `app` gets `imagePullPolicy: Always`
3. The Deployment's own label `retired` is gone — the label `app: plating`
   must survive

`kubectl kustomize` must render without error, and the container's existing
port, image and resource requests must be untouched. Apply the overlay; the
Pod must be Running. Do not modify the base.

> Target: 5 minutes. Three changes, three different situations — exactly one
> of the three is a path that is not in the base yet, and one operation
> refuses to work on a path that is not there.

---

# Q9 (topic: Deployment level vs Pod level in one patch)

Deployment `smelter` comes from `/course5/9/base`; the overlay
`/course5/9/overlays/prod` already points at it. Team Bronze wants a slower,
safer rollout.

Using **one patch** in the overlay, make all three of these changes:

1. The **Deployment** waits `20` seconds before treating a new Pod as
   available (`minReadySeconds`)
2. The **Pod** gets `45` seconds to shut down (`terminationGracePeriodSeconds`)
3. The **Pod template** carries the label `tier: smelting` — the Deployment's
   own `metadata.labels` must NOT gain it, and no selector may change

Apply the overlay and wait for the rollout. Do not modify the base.

```bash
kubectl -n bronze get deploy smelter --show-labels     # tier must NOT be here
kubectl -n bronze get pod --show-labels                # tier must be here
```

> **Second pass — do this question twice.** Solve it first with a **strategic
> merge** patch and run `verify.sh`. Then delete your patch and produce the
> exact same result with a **JSON 6902** patch, and verify again.
> `verify.sh` checks the outcome, not the mechanism, so both passes come back
> green.
>
> Target: 4 minutes per pass. Every one of the three fields hangs off a
> different depth of the same tree — write the path out loud before you type
> it.

---

# Q10 (topic: JSON 6902 on a list — index, insert, append)

Deployment `foundry` at `/course5/10/base` runs two containers, `app` then
`log`. The overlay `/course5/10/overlays/prod` already points at the base.

Using a **JSON 6902 patch** in the overlay (JSON 6902 only — no strategic
merge patch file anywhere in the overlay), make the container list end up
**exactly this, in this order**:

| # | name | image | command |
|---|---|---|---|
| 0 | `proxy` | `busybox:1` | `sh -c "sleep 86400"` |
| 1 | `app` | `nginx:1.27-alpine` | — |
| 2 | `log` | `busybox:1` | unchanged |
| 3 | `metrics` | `busybox:1` | `sh -c "sleep 86400"` |

`proxy` and `metrics` are new. `app` changes **only** its image — its
`ports` and `resources` must survive exactly as they are in the base. `log`
is untouched.

Apply the overlay. All four containers must be Ready. Do not modify the base.

```bash
kubectl -n pewter get deploy foundry -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'
```

> Target: 6 minutes. The ops in one patch run in order, one after another,
> against the list as the previous op left it — so the index you need for the
> image edit depends on where you put the insert.

---

# Q11 (topic: RFC 6901 escaping in a JSON 6902 path)

Deployment `bell` at `/course5/11/base` was generated by a templating tool
that left junk in its metadata:

```yaml
metadata:
  name: bell
  labels:
    app: bell
    app.kubernetes.io/managed-by: helm
  annotations:
    brass.io/team: brass
    nginx.ingress.kubernetes.io/rewrite-target: /
    brass.io/cost~center: "smelting-eu"
```

Using a **JSON 6902 patch** in the overlay `/course5/11/overlays/prod`
(JSON 6902 only — no strategic merge patch file anywhere in the overlay):

1. Label `app.kubernetes.io/managed-by` becomes `kustomize`
2. Annotation `nginx.ingress.kubernetes.io/rewrite-target` is removed
3. Annotation `brass.io/cost~center` is removed
4. Annotation `app.kubernetes.io/version` is added with value `"2.1.0"`

Label `app: bell` and annotation `brass.io/team` must survive. Apply the
overlay; the Deployment must be Ready. Do not modify the base.

> Target: 6 minutes. A JSON Pointer is `/`-delimited, so a key that contains
> `/` is not one path segment unless you make it one — and one of these keys
> needs two different escapes applied in a particular order.

---

# Q12 (topic: configMapGenerator — the four input forms)

Deployment `renderer` is already applied into Namespace `gallium` from the
overlay `/course5/12/overlays/prod`. Its Pod will not start: it mounts a
ConfigMap `gallium-config` and reads one environment variable out of it, and
that ConfigMap does not exist.

The source data is already sitting in the overlay directory:

    /course5/12/overlays/prod/app.properties
    /course5/12/overlays/prod/content/landing.html
    /course5/12/overlays/prod/runtime.env

Generate `gallium-config` from the overlay's `kustomization.yaml` so that it
ends up holding exactly these keys:

1. `app.properties` — the contents of `app.properties`
2. `index.html` — the contents of `content/landing.html` (note the key is
   **not** the file name)
3. `LOG_LEVEL` — the value `warn`, which is not in any file
4. `MAX_CONNECTIONS` and `CACHE_TTL` — one key per line of `runtime.env`

Apply the overlay. The Pod must end up Running, and the generated name must
never be typed by you — the Deployment's two references to `gallium-config`
are rewritten by the build.

Do not modify the base.

> Target: 6 minutes. Three of the four inputs are files on disk, but they do
> not all belong under the same generator field — one file has to produce two
> keys.

---

# Q13 (topic: the generated name hash — keep it or kill it)

Namespace `indium` has two Deployments and neither one starts:

- `broker`, applied from the overlay `/course5/13/overlays/prod`, reads
  `username` and `password` from a Secret `broker-auth`
- `audit`, which is **not** part of any Kustomize build (it was applied
  straight from `/course5/13/audit.yaml`), mounts a ConfigMap `broker-rules`
  at `/etc/rules`

From the overlay's `kustomization.yaml`, generate both objects:

1. Secret `broker-auth`, type `Opaque`, from the literals `username=indium`
   and `password=bismuth-77`. It must **keep** its generated hash suffix, and
   Deployment `broker` must end up referencing that hashed name — which you
   never type yourself
2. ConfigMap `broker-rules` from the file `rules.conf` in the overlay
   directory (key = the file name). It must be named **exactly**
   `broker-rules`, because `audit` is already running and asks for that name
3. Apply the overlay. Both `broker` and `audit` must become Ready

Do not modify the base, and do not edit or re-create the `audit` Deployment —
it stands in for something outside your build that you do not control.

> Target: 6 minutes. `disableNameSuffixHash` can be written in two different
> places and only one of them leaves the Secret's hash alone.

---

# Q14 (topic: overriding a base's generator — `behavior: merge` vs `replace`)

The **base** at `/course5/14/base` declares both of Deployment `catalog`'s
ConfigMaps itself, with `configMapGenerator`:

    app-settings   LOG_LEVEL=info   REGION=eu-west   TIMEOUT=30
    feature-flags  beta_ui=false    dark_mode=false  new_billing=false

`catalog` is running in Namespace `osmium` from the overlay
`/course5/14/overlays/prod` with exactly those values. Change them from the
overlay so that after `kubectl apply -k`:

1. `app-settings` holds `LOG_LEVEL=debug`, a new key `TRACE_SAMPLING=0.5`,
   and still holds `REGION=eu-west` and `TIMEOUT=30`
2. `feature-flags` holds `beta_ui=true` and `dark_mode=true` and **nothing
   else** — `new_billing` must be gone from the ConfigMap entirely
3. `catalog` is still Ready, and both of its `envFrom` references point at
   the ConfigMaps you produced

Do not modify the base. Your overlay must not restate a value the base
already has right: the strings `REGION` and `TIMEOUT` must not appear
anywhere in `/course5/14/overlays/prod`.

> Target: 6 minutes. The two generators need the same one-word field set to
> two different values — and the wrong value on the first one silently drops
> two keys.

---

# Q15 (topic: reading Kustomize build errors)

A colleague left the staging overlay for team Cadmium in this state:

```
$ kubectl kustomize /course5/15/overlays/staging
error: invalid Kustomization: json: unknown field "configmapGenerator"
```

There are **three** independent faults in
`/course5/15/overlays/staging/kustomization.yaml`, and Kustomize will only
ever show you one at a time. Nothing is deployed yet.

Fix the overlay so that `kubectl apply -k /course5/15/overlays/staging`
produces, in Namespace `cadmium`:

1. Deployment `stg-pigment`, `2` replicas, all Ready
2. Service `stg-pigment`
3. A generated ConfigMap holding the key `app.conf` with the contents of
   `/course5/15/overlays/staging/app.conf`, mounted by the Deployment at
   `/etc/pigment`

Every fix belongs in the overlay's `kustomization.yaml`. Do not modify
anything in `/course5/15/base`, and do not rename, move or create any file on
disk — what is on disk is correct.

> Target: 6 minutes. Fix one, re-render, read the next. The order the errors
> come out in is itself the lesson: Kustomize checks the kustomization's own
> field names before it ever looks at a path.

---

# Q16 (topic: build a whole overlay from blank — capstone)

`/course5/16/base` holds Deployment `gauge` (container `web`, image
`nginx:1-alpine`, one env var `MODE=gauge`, and a volume mounting a ConfigMap
`gauge-config` that does not exist yet) and Service `gauge`.

`/course5/16/overlays/prod` is **empty**. Build the whole overlay there, on
top of the base, so that a single `kubectl apply -k` produces all of this:

1. Everything lands in Namespace `mercury` (exists)
2. Every resource name is prefixed with `hg-`
3. Deployment `gauge` runs `3` replicas
4. The `nginx` image is used at tag `1.27-alpine`
5. Every resource carries the label `env: prod` — **without** any selector
   changing
6. ConfigMap `gauge-config` is generated from the literals `UNITS=metric` and
   `SCALE=celsius`; the Deployment's volume must end up pointing at the
   generated object without you typing its name
7. Using a **patch**, container `web` gets a second environment variable
   `READ_ONLY` with the value `true`, and keeps `MODE=gauge`

Apply it. All 3 Pods must be Ready. Do not modify the base.

> Target: 10 minutes. Three different fields in this overlay take the name a
> resource has in the **base**, not the name it will have once the prefix is
> applied.

> **Second pass — do this question twice.** Solve it first with a **strategic
> merge** patch for deliverable 7 and run `verify.sh`. Then delete your patch
> and produce the same result with a **JSON 6902** patch, and verify again.
> `verify.sh` checks the outcome, not the mechanism, so both passes come back
> green.
>
> Target: 10 minutes for the first pass. On the second only the patch changes
> — 2 minutes.

