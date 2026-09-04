# Exam Set 4 — all tasks (print/read this during a timed run)

16 questions, Helm and Kustomize only. On the real exam these topics are
maybe two or three questions out of ~16, so treat this set as a drill rather
than a mock: pace at **~6 min/question**, and anything you can't finish in
that time is a topic to read up on afterwards.

Everything runs on the control plane over SSH, like the exam: `helm`,
`kubectl`, vim. There is no standalone `kustomize` binary — `kubectl
kustomize` and `kubectl apply -k` are what you have.

| # | Topic | Namespace | Difficulty |
|---|---|---|---|
| q01 | Helm repo, search, versions | — | warm-up |
| q02 | Helm install with values, specific version | beryl | easy |
| q03 | Helm upgrade keeping values | coral | medium |
| q04 | Helm history + rollback | garnet | medium |
| q05 | Helm housekeeping, find a stuck release | jade/onyx | medium |
| q06 | helm template to a file | pearl | medium |
| q07 | debug + fix a release via its values file | quartz | medium |
| q08 | helm pull, install from a directory | ruby | easy |
| q09 | Kustomize render/apply, namespace | topaz | warm-up |
| q10 | Kustomize overlay from scratch | zircon | medium |
| q11 | strategic merge patch | agate | medium |
| q12 | JSON 6902 patch | jasper | **hard** |
| q13 | ConfigMap/Secret generators | lapis | **hard** |
| q14 | fix a broken Kustomization | slate | medium |
| q15 | images/replicas transformers, delete -k | amethyst | medium |
| q16 | components | obsidian | easy (bonus) |

---

# Q1 (topic: Helm repositories)

Team Amber wants an overview of the company's internal chart repository. It is
served at `http://localhost:6100` on the control-plane host.

1. Make sure it is registered in Helm under the repo name `hk-charts` (add it
   if it isn't)
2. Write the names of all charts the repository offers, one per line, to
   `/course4/1/charts`
3. Write all available versions of chart `hk-charts/api`, one *chart version*
   per line, newest first, to `/course4/1/api-versions`

---

# Q2 (topic: Helm install with values)

Team Beryl needs the internal API deployed:

1. Install chart `hk-charts/api` in chart version `2.1.0` (deliberately *not*
   the latest) as release `beryl-api` into Namespace `beryl`. The Namespace
   does not exist yet — have Helm create it.
2. Configure the release **via Helm values** so that:
   - the Deployment runs `3` replicas
   - the Service is of type `NodePort` using node port `30402`
   - the container has an environment variable `LOG_LEVEL` with value `debug`
3. Confirm the app answers on the node port, e.g. from the control-plane host:
   `curl http://10.10.1.10:30402`

---

# Q3 (topic: Helm upgrade)

Release `coral-web` in Namespace `coral` was installed from chart
`hk-charts/nginx` some time ago, with custom values.

1. Upgrade the release to the newest chart version available in the repo
2. As part of the same upgrade, change the image tag to `1.27-alpine`
3. The replica count and the node port the release was originally installed
   with must stay exactly as they are — the team relies on them
4. Write the revision number the release has after your upgrade to
   `/course4/3/revision`

---

# Q4 (topic: Helm history and rollback)

The most recent upgrade of release `garnet-api` in Namespace `garnet` went
wrong: the new Pods never become ready.

1. Inspect the release history and identify the last revision that worked
2. Roll the release back to that revision. Do **not** fix the problem with a
   new upgrade — the team wants Helm's rollback mechanism used
3. Afterwards write the revision number that is now deployed to
   `/course4/4/revision`, and the chart version now deployed (just the
   version, e.g. `1.2.3`) to `/course4/4/chart-version`

---

# Q5 (topic: Helm release housekeeping)

Teams Jade and Onyx share the cluster. Do some Helm housekeeping for them:

1. Uninstall release `onyx-legacy` in Namespace `onyx`
2. Upgrade release `onyx-web` (Namespace `onyx`) to the newest available
   version of its chart, keeping the values it was installed with
3. Somewhere in the cluster a release is stuck in a `pending-*` status after
   a Helm operation was interrupted. Find it and uninstall it. Before you do,
   write `<namespace>/<release-name>` to `/course4/5/stuck`
4. Write the number of Helm releases that remain in Namespaces `jade` and
   `onyx` combined to `/course4/5/count`

---

# Q6 (topic: helm template)

Team Pearl likes the chart at `/course4/6/chart` but does not want Helm to
manage the deployment — they apply plain manifests with kubectl.

1. Render the chart with release name `pearl-web` for Namespace `pearl`,
   using the values file `/course4/6/prod-values.yaml` and, on top of it,
   `3` replicas
2. Save the rendered manifests to `/course4/6/pearl-web.yaml`
3. Create the resources in Namespace `pearl` (exists) from that file with
   kubectl
4. There must be no Helm release `pearl-web` afterwards

---

# Q7 (topic: Helm values file, debugging a release)

Release `quartz-api` in Namespace `quartz` was installed from
`hk-charts/api` version `2.2.0` with the values file
`/course4/7/values.yaml`, but its Pods never became ready.

1. Find the cause
2. Fix it in `/course4/7/values.yaml` — the file must stay the single source
   of truth for this release, so do not use `--set`, and keep everything else
   in the file as it is
3. Apply the fix to the release so that all its Pods are running

---

# Q8 (topic: Helm pull and local charts)

Team Ruby wants to vendor a chart into their own repository and adjust its
defaults.

1. Download chart `hk-charts/redis` in version `0.6.0` (not the latest) to
   `/course4/8/` and extract it there, so that `/course4/8/redis/Chart.yaml`
   exists
2. Change the chart's *default* for `replicaCount` to `2` in its `values.yaml`
3. Install the chart **from that local directory** as release `ruby-cache`
   into Namespace `ruby` (create it). Pass no values on the command line —
   the edited default must do the work

---

# Q9 (topic: Kustomize basics)

A Kustomization for the Topaz app lives at `/course4/9/app` on the
control-plane host.

1. All its resources must be deployed into Namespace `topaz` (exists).
   Configure that inside the Kustomization, not with a kubectl flag
2. Save the fully rendered output of the Kustomization to
   `/course4/9/rendered.yaml`
3. Apply the Kustomization
4. Write the number of Kubernetes resources the Kustomization renders to
   `/course4/9/count`

---

# Q10 (topic: Kustomize overlays and transformers)

Base manifests for the Zircon web app are at `/course4/10/base` on the
control-plane host. Create an overlay at `/course4/10/overlays/staging`
which, on top of the base:

1. Places all resources in Namespace `zircon` (exists)
2. Prefixes every resource name with `stg-`
3. Runs the Deployment with `2` replicas
4. Uses image tag `1.27-alpine` for the `nginx` image
5. Adds the label `env: staging` to every resource — without touching any
   selectors

Apply the overlay. Do not modify the base.

---

# Q11 (topic: Kustomize strategic merge patch)

The prod overlay `/course4/11/overlays/prod` is deployed in Namespace
`agate`. Ops asks for resource settings and a readiness check on container
`api` of Deployment `agate-api`:

- requests: cpu `50m`, memory `32Mi`; limits: memory `64Mi`
- a readinessProbe doing an HTTP GET on path `/` port `80`, every `5`
  seconds

Implement this as a **strategic merge patch** in its own file
`/course4/11/overlays/prod/patch-resources.yaml`, referenced from the
overlay's kustomization. Apply the overlay. The base must not change.

---

# Q12 (topic: Kustomize JSON 6902 patch)

Deployment `jasper-worker` is deployed from overlay
`/course4/12/overlays/dev` into Namespace `jasper`. Using a **JSON 6902
patch** in the dev overlay (inline or in a file, but JSON 6902 — not
strategic merge), make these changes to the Deployment:

1. Change the value of the existing environment variable `MODE` (the first
   entry in the container's env list) from `batch` to `stream`
2. Add a second environment variable `DEBUG` with value `true` at the end
   of the env list
3. Remove the annotation `jasper.io/legacy-owner` from the Deployment's
   metadata. The other annotation must stay

Apply the overlay. The base must not change.

---

# Q13 (topic: Kustomize generators)

Overlay `/course4/13/overlays/prod` deploys Deployment `lapis-app` into
Namespace `lapis`. Its Pod is stuck: the Deployment mounts a ConfigMap
`app-config` and reads a Secret `db-creds`, and neither exists.

Generate both from the overlay's kustomization:

1. ConfigMap `app-config` from the file `app.properties` in the overlay
   directory (key = the file name) plus the literal `LOG_LEVEL=warn`
2. Secret `db-creds` from the literals `username=lapis` and
   `password=ruby-lapis-42`
3. The Secret must be named exactly `db-creds`, without a hash suffix — an
   external tool reads it by that name. The ConfigMap may keep its suffix

Apply the overlay so that the Pod runs.

---

# Q14 (topic: Kustomize troubleshooting)

Someone broke the Kustomize setup at `/course4/14`:
`kubectl apply -k /course4/14/overlays/prod` fails.

Fix all problems, editing only Kustomization files. The Kubernetes
manifests (`deployment.yaml`, `service.yaml`) are correct and must not be
modified or renamed.

When you are done, the overlay must apply cleanly and deploy Deployment
`slate-web` with `2` replicas into Namespace `slate`, with the label
`team: slate` on every resource.

---

# Q15 (topic: Kustomize images and replicas, delete -k)

Team Amethyst runs a dev and a prod environment from `/course4/15`.

1. The dev environment (overlay `/course4/15/overlays/dev`, Namespace
   `amethyst-dev`) is no longer needed. Remove everything it deployed
   **using Kustomize** — do not delete the Namespace itself
2. Adjust the prod overlay `/course4/15/overlays/prod` so that:
   - image `nginx` is replaced by `nginx:1.27-alpine` and image `redis` gets
     tag `7.2-alpine` — use the `images` transformer, not patches
   - Deployment `web` runs `3` replicas and Deployment `cache` runs `1` —
     use the `replicas` field, not patches
3. Apply the prod overlay (it targets Namespace `amethyst`, which exists)

---

# Q16 (topic: Kustomize components)

`/course4/16` holds a base, a `dev` and a `prod` overlay (deployed into
Namespaces `obsidian-dev` and `obsidian`), and a reusable feature bundle at
`/course4/16/components/monitoring`.

Enable the monitoring component for **prod only**, then apply both overlays
so the cluster reflects it: in `obsidian`, Deployment `obsidian-app` gets the
component's `METRICS_ENABLED` environment variable and ConfigMap
`monitoring-config` exists; `obsidian-dev` stays without both.

Do not modify the base or the component.


---

The speed kit from Set 1 still applies — see `../EXAM-SPEED.md`.

## Traps in this set, from the questions themselves

Read these *after* your timed run, not before — they're the mistakes the set
is built to catch.

<details>
<summary>Spoilers</summary>

- **q01** — `helm search repo` shows only the newest version; `--versions`
  shows all. The file wants CHART VERSION, not APP VERSION.
- **q02** — `--version` picks the chart version; `-n` needs
  `--create-namespace`; "via Helm values" is graded with `helm get values`.
- **q03** — `helm upgrade` forgets previous `--set`s. `--reuse-values` or
  re-pass everything; `helm get values` tells you what "everything" is.
- **q04** — `helm rollback` creates a *new* revision (4), it doesn't rewind
  to 2.
- **q05** — `helm ls` hides `pending-*` releases: `helm ls -A -a`.
- **q06** — `-n` on `helm template` doesn't put a namespace in the YAML;
  the `kubectl apply` needs `-n` too. `--set` beats `-f`.
- **q07** — editing the values file changes nothing until `helm upgrade -f`
  re-reads it; an upgrade without `-f` resets the other values.
- **q08** — `helm pull --untar -d <dir>`; a chart *path* installs from disk,
  a bare name is looked up in the repos.
- **q09** — `apply -f` on a Kustomize directory fails; `-k`. Set the
  namespace *before* saving the render.
- **q10** — `commonLabels` rewrites selectors; `labels:` (list form) does
  not. `replicas.name` is the base name, not the prefixed one.
- **q11** — a strategic merge patch on `containers` must carry
  `- name: api` or nothing matches.
- **q12** — `/` in a key is `~1`; env values must be quoted strings
  (`"true"`); `/-` appends, an index inserts.
- **q13** — generated names get a hash; the Deployment's references are
  rewritten for you. `disableNameSuffixHash` is per generator under
  `options:`.
- **q14** — fix one error, re-render, read the next. Paths are relative to
  the kustomization that lists them.
- **q15** — `apply -k` never prunes; `delete -k` renders and deletes the same
  set. `images.name` is the image name, not the container name.
- **q16** — `kind: Component`, included via `components:`, never
  `resources:`.

</details>
