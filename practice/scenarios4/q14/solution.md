# Q14 solution

Let Kustomize tell you what's wrong — one error at a time:

```bash
kubectl kustomize /course4/14/overlays/prod
```

**Error 1** — `invalid Kustomization: json: unknown field "commonLabel"`.
Kustomize validates the file's fields before it resolves any paths, so a
typo in a key is always the first thing you see. The field is plural:

```yaml
commonLabels:
  team: slate
```

(or the newer `labels: [{pairs: {team: slate}}]` — both put the label on
every resource; `commonLabels` prints a deprecation warning but works.)

**Error 2** — `accumulating resources from '../base': ... lstat
/course4/14/overlays/base: no such file or directory`. The overlay points at
`../base`, but from `overlays/prod/` the base is two levels up:

```yaml
resources:
  - ../../base
```

**Error 3** — `accumulating resources from 'deployment.yml': ... lstat
/course4/14/base/deployment.yml: no such file or directory`. The base
kustomization lists `deployment.yml`; the file is `deployment.yaml`. Fix the
*kustomization*, not the file name (the task forbids renaming):

```yaml
resources:
  - deployment.yaml
  - service.yaml
```

```bash
kubectl kustomize /course4/14/overlays/prod     # now renders
kubectl apply -k /course4/14/overlays/prod
k -n slate get deploy,svc --show-labels
```

## Reading Kustomize errors

- **"unknown field"** — a typo in a kustomization key. The file is strictly
  validated, before anything else: singular/plural and capitalisation matter
  (`commonLabels`, `namePrefix`, `configMapGenerator`).
- **"no such file or directory"** — a path in `resources:`. The message
  names the path it tried (`/course4/14/overlays/base`), which tells you
  where the hop count went wrong. Paths are relative to the kustomization
  file that lists them; a nested error (`recursed accumulation of path`)
  means the problem is inside the base, not the overlay.
- **"must be a directory"** / **"kustomization.yaml not found"** — you pointed
  at a file, or at a directory without a kustomization.

Fix one, re-render, read the next. Three errors here, three rounds.
