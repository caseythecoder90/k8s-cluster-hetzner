# CI deployer — GitHub Actions → this cluster

Lets each app repo roll out a new image without holding admin credentials.
The app repos keep building and pushing to GHCR exactly as before; only their
`deploy` job changes (SSH-to-VPS → `kubectl set image`).

## What the identity can do

`ci-deployer` in each app namespace: update the image on existing Deployments,
watch the rollout, read pods and pod logs. It **cannot** read Secrets, create
resources, or see other namespaces — so a leaked CI token is a bounded problem.

## Setup (once per namespace)

```bash
kubectl apply -f kubernetes/cluster/ci-deployer/rbac.yaml
./scripts/gen-ci-kubeconfig.sh personal-website   # copy the output
./scripts/gen-ci-kubeconfig.sh grindtrack
```

Each command prints one long base64 line. In the matching GitHub repo →
**Settings → Secrets and variables → Actions → New repository secret**:

| Repo | Secret name | Value |
|---|---|---|
| `personal-website-backend` | `KUBE_CONFIG` | output for `personal-website` |
| `personal-website-frontend` | `KUBE_CONFIG` | output for `personal-website` |
| `grindtrack` | `KUBE_CONFIG` | output for `grindtrack` |

The old `VPS_HOST` / `VPS_USER` / `VPS_SSH_KEY` secrets can be deleted once the
old server is decommissioned.

## The replacement deploy job

Drop-in for the `deploy:` job in each workflow — everything above it (tests,
build, push to GHCR) stays untouched:

```yaml
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: production
    concurrency:
      group: deploy-production
      cancel-in-progress: false
    steps:
      - uses: azure/setup-kubectl@v4
        with:
          version: v1.33.13          # match the cluster (kubectl allows ±1 minor)

      - name: Configure cluster access
        run: |
          mkdir -p ~/.kube
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > ~/.kube/config
          chmod 600 ~/.kube/config

      - name: Roll out the new image
        run: |
          TAG=${GITHUB_SHA::7}       # matches docker/metadata-action type=sha,prefix=
          kubectl -n <NAMESPACE> set image deploy/<DEPLOYMENT> <CONTAINER>=ghcr.io/caseythecoder90/<IMAGE>:$TAG
          kubectl -n <NAMESPACE> rollout status deploy/<DEPLOYMENT> --timeout=300s
```

Per-repo values:

| Repo | NAMESPACE | DEPLOYMENT | CONTAINER | IMAGE |
|---|---|---|---|---|
| `grindtrack` | `grindtrack` | `grindtrack` | `app` | `grindtrack` |
| `personal-website-backend` | `personal-website` | `backend` | `backend` | `personal-website-backend` |
| `personal-website-frontend` | `personal-website` | `frontend` | `frontend` | `personal-website-frontend` |

## Why the SHA tag rather than `:latest`

`rollout status` can then actually tell success from failure. With `:latest`
the pod spec never changes, so `kubectl` has nothing to roll out — you'd need
`rollout restart` and you'd lose the ability to say *which* build is running.
An immutable SHA tag also makes rollback trivial:

```bash
kubectl -n grindtrack rollout undo deploy/grindtrack
```

## Known drift

CI sets a SHA tag on the live Deployment, while the manifests in
`kubernetes/apps/*/base/` still say `:latest`. So the cluster and this repo
disagree about the running image — re-applying a kustomization would knock the
app back to `:latest`.

Two ways to close that, later:

1. Pin the tag in the overlay's `images:` block on each release (manual, honest).
2. Adopt Argo CD: CI commits the new tag to this repo, Argo syncs it. The
   cluster then has no CI credentials at all and Git is the source of truth.

Until then: **don't re-apply the app kustomizations without checking the live
image first** (`kubectl -n grindtrack get deploy grindtrack -o jsonpath='{..image}'`).
