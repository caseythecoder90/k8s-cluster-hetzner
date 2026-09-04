# CKAD practice — Exam Set 4: Helm + Kustomize (original questions)

Sixteen original questions, all Helm and Kustomize, written in the killer.sh
style (a team, a Namespace, precise deliverables, one trap each) to the depth
the CKAD actually asks: *use* Helm to deploy and manage existing packages,
*use* Kustomize to render and customise manifests. Nothing about authoring
charts from scratch. Same framework as Sets 1–3: `setup.sh` / `TASK.md` /
`verify.sh` / `solution.md` per question.

Uses `/course4/N/...` for files and gemstone Namespaces (`amber` … `obsidian`),
so it never collides with Sets 1–3 (planets, trees) if they're loaded on the
same cluster.

## Workflow

```bash
./setup-all.sh           # build all 16 starting states (~10 min; the chart repo is built once)
cat TASKS-ALL.md         # read the questions
# ...solve on the control plane, exam-style...
./verify-all.sh          # score yourself
```

Single question:

```bash
./setup-all.sh q05
cat q05/TASK.md
./verify-all.sh q05
```

Re-running a question's `setup.sh` resets it. `./cleanup.sh` removes
everything the set created (Namespaces, `/course4`, the chart server) and
leaves the other sets alone.

## Which cluster

By default the scripts talk to the normal lab (Terraform default workspace,
`ansible/kubeconfig/admin.conf`). A second lab built in another Terraform
workspace is addressed with `LAB_WORKSPACE=<workspace> ./setup-all.sh` — see
`../README.md`.

## The exam environment, and how this set mimics it

- **Helm is installed** on the exam node; the docs at helm.sh are allowed. The
  charts you're asked to work with come from a repo already reachable from the
  node. Here that's `hk-charts`, served on the control plane at
  `http://localhost:6100` (killer.sh does the same on `localhost:6000`), with
  three charts in several versions: `api` 1.0.0/2.0.0/2.1.0/2.2.0, `nginx`
  1.0.0/1.1.0/1.2.0, `redis` 0.5.0/0.6.0/0.7.1.
- **Only kubectl's built-in Kustomize is guaranteed** (`kubectl kustomize`,
  `kubectl apply -k`). The standalone `kustomize` binary — and with it
  `kustomize edit set image ...` — is not promised, and it's deliberately not
  installed in this lab. Practise editing `kustomization.yaml` in vim.
- kubectl 1.33 embeds Kustomize v5, so the modern fields (`patches:`,
  `labels:`, `replicas:`, `resources:` for bases) all work, and so do the
  deprecated ones (`commonLabels`, `bases:`, `patchesStrategicMerge`).

## What was adapted, and why

| # | Adaptation |
|---|---|
| q04 | The "broken upgrade" is a non-existent image tag, so the rollout stalls while the old Pods keep serving — the same picture as a real bad release, and `helm` still reports the revision as `deployed`. |
| q05 | The `pending-upgrade` release is produced by rewriting Helm's release Secret (see `lib/helm-repo.sh`), which is exactly what a helm process killed mid-upgrade leaves behind. |
| q02/q03/q06/q07 | NodePorts are checked by curling the node's private IP (`10.10.1.10`), not `localhost`. |

## Questions that write to the node

- Every question writes under `/course4/N`; the chart repo lives under
  `/course4/_repo`, and checksums of files you must not modify under
  `/course4/_check`.
- q01 (and every Helm question's setup) leaves a `python3 -m http.server`
  on port 6100 serving the chart repo, bound to localhost.

All of it disappears with `./cleanup.sh` or `terraform destroy`.

## Topic map

| # | Topic | Namespace | Difficulty |
|---|---|---|---|
| q01 | `helm repo add`, `search repo --versions`, chart vs app version | — | warm-up |
| q02 | `install --version --create-namespace`, values file vs `--set` | beryl | easy |
| q03 | `upgrade` keeps values? `--reuse-values`, `helm get values` | coral | medium |
| q04 | `history`, `rollback`, rollback = new revision | garnet | medium |
| q05 | `ls -A -a`, pending-* releases, uninstall/upgrade housekeeping | jade/onyx (+opal) | medium |
| q06 | `helm template` to a file, `-f` + `--set` precedence, apply with kubectl | pearl | medium |
| q07 | debug a release, fix the values file, `upgrade -f` | quartz | medium |
| q08 | `helm pull --untar`, edit chart defaults, install from a directory | ruby | easy |
| q09 | `kubectl kustomize` / `apply -k`, `namespace:` transformer | topaz | warm-up |
| q10 | create an overlay: namespace, namePrefix, replicas, images, labels | zircon | medium |
| q11 | strategic merge patch in a file: resources + readinessProbe | agate | medium |
| q12 | JSON 6902 patch: replace/add/remove, `~1` escaping, quoted `"true"` | jasper | **hard** |
| q13 | configMapGenerator/secretGenerator, hash suffix, `disableNameSuffixHash` | lapis | **hard** |
| q14 | fix a broken Kustomization: path, file name, unknown field | slate | medium |
| q15 | `delete -k`, `images:` with two images, `replicas:` for two Deployments | amethyst(-dev) | medium |
| q16 | components (`kind: Component`, `components:`) — beyond typical exam depth | obsidian(-dev) | easy |
