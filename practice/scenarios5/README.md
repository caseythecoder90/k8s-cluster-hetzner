# CKAD practice — Exam Set 5: Kustomize, cold (original questions)

Sixteen original questions on Kustomize only, written to the exact syllabus of
`notes/11-kustomize/13-memorize-cold.md` in the ckad-exam-prep repo. That file
exists because **`kubectl.docs.kubernetes.io` is not on the exam's allowed-docs
list** — the only reachable Kustomize page is the single
`kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/` worked
example, and searching it under time pressure costs more than it returns. This
set is the drill that makes the lookup unnecessary.

Uses `/course5/N/...` for files and metal Namespaces (`copper` … `mercury`), so
it never collides with Sets 1–4 (planets, trees, gemstones) or Set 6 (rivers)
on the same cluster.

## Workflow

```bash
./setup-all.sh           # build all 16 starting states
cat TASKS-ALL.md         # read the questions
# ...solve on the control plane, exam-style...
./verify-all.sh          # score yourself
```

Single question:

```bash
./setup-all.sh q07
cat q07/TASK.md
./verify-all.sh q07
```

Re-running a question's `setup.sh` resets it. `./cleanup.sh` removes everything
this set created and leaves the other sets alone.

## Doing the patch questions twice

Six questions can be solved with either patch strategy, and their `verify.sh`
checks the **outcome**, not the mechanism. Their `TASK.md` carries a **Second
pass** note: solve it with a strategic merge, verify, delete the patch, redo it
with JSON 6902, verify again. Both passes go green. That is the point — you
finish the set having written every change both ways.

The other patch questions **force** one strategy, because the mechanism is the
lesson (`$patch: delete` and `key: null` only exist in strategic merge; `~1`
escaping and index arithmetic only exist in JSON 6902). Those `verify.sh`
scripts grep for the required mechanism and reject the other one.

## The exam environment, and how this set mimics it

- **Only kubectl's built-in Kustomize is guaranteed** (`kubectl kustomize`,
  `kubectl apply -k`, `kubectl delete -k`, `kubectl diff -k`). The standalone
  `kustomize` binary — and with it `kustomize edit set image ...` — is not
  promised, and is deliberately not installed in this lab. Every question is
  solved by editing `kustomization.yaml` in vim.
- kubectl 1.33 embeds Kustomize v5, so the modern fields (`patches:`, `labels:`,
  `replicas:`, `images:`, `components:`) all work, and the deprecated ones
  (`commonLabels`, `bases:`, `patchesStrategicMerge`) still parse. Questions are
  written against the modern spellings.
- Several questions leave a Pod deliberately `Pending` or a build deliberately
  broken until the answer is right, so the cluster itself tells you when you
  have it — the same feedback loop the exam gives you.

## Topic map

Section numbers refer to `13-memorize-cold.md`.

| # | Topic | § | Namespace | Strategy | Difficulty |
|---|---|---|---|---|---|
| q01 | `kubectl kustomize` vs `apply -k`; namespace/prefix/suffix/annotations | 1, 2 | copper | — | warm-up |
| q02 | `replicas:` and `images:` transformers; base-name and image-name traps | 2 | silver | — | easy |
| q03 | `labels:` vs `commonLabels` on a live Deployment (immutable selector) | 2, 9 | cobalt | — | medium |
| q04 | patch a map: add a limit, add an annotation | 4, 5 | nickel | **both** | medium |
| q05 | delete with `key: null`; the Pod stays Pending until you do | 4 | zinc | forced SMP | medium |
| q06 | container lists: merge key, add, `$patch: delete` | 4 | tin | forced SMP | medium |
| q07 | scalar lists (`args:`) are replaced wholesale, never merged | 4 | iron | **both** | medium |
| q08 | `add` vs `replace` vs `remove` semantics | 5 | chrome | forced 6902 | medium |
| q09 | `/spec` vs `/spec/template/spec` — the one-hop error | 6 | bronze | **both** | medium |
| q10 | list positions: `/-` append, `/0` insert, element vs field replace | 7 | pewter | forced 6902 | **hard** |
| q11 | RFC 6901 escaping: `~1` for `/`, `~0` for `~`, in that order | 8 | brass | forced 6902 | **hard** |
| q12 | `configMapGenerator`: files, `key=path`, literals, envs | 3 | gallium | — | medium |
| q13 | `secretGenerator`, the hash suffix, `disableNameSuffixHash` | 3 | indium | — | **hard** |
| q14 | generator `behavior: merge` / `replace` over a base generator | 3 | osmium | — | **hard** |
| q15 | debug a broken build: unknown field, bad path, wrong file name | 9 | cadmium | — | medium |
| q16 | capstone: build a full overlay from blank, timed | 10 | mercury | **both** | **hard** |

## What this set deliberately does not cover

`components:` (Set 4 q16 has it, and it is beyond typical exam depth), chart
authoring, and anything requiring the standalone `kustomize` binary.
