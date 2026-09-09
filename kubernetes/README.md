# Kubernetes manifests

Everything the cluster *runs*, managed with Kustomize (built into kubectl).

```
cluster/          Cluster-scoped foundations (apply first)
  namespaces/     Namespace definitions
  ingress-nginx/  Ingress controller (install notes inside)
apps/             One directory per application
  <app>/base/     Environment-agnostic manifests
  <app>/overlays/prod/   Prod-specific patches (namespace, replicas, hosts)
```

## Apply order

```bash
kubectl apply -k kubernetes/cluster/namespaces
# install ingress controller — see cluster/ingress-nginx/README.md
# install storage + cert-manager — see their READMEs; full order: docs/05-app-migration.md
kubectl apply -k kubernetes/apps/personal-website/overlays/prod
kubectl apply -k kubernetes/apps/grindtrack/overlays/prod
kubectl apply -k kubernetes/apps/keycloak/overlays/prod   # platform service, before ours
kubectl apply -k kubernetes/apps/ours/overlays/prod
```

`keycloak/` and `ours/` need hand-made Secrets before they start; the exact
commands are in the caseyas repo, `docs/milestone-1-runbook.md` and
`docs/milestone-2-runbook.md`.

`ours/base/minio.yaml` and `storage-ingress.yaml` are an **interim** object
store standing in for Cloudflare R2 (served under the app's own origin at
`/ours/…` so presigned URLs work without a media DNS record). When the R2
bucket exists: recreate the `ours-storage` secrets with the R2 values, remove
both files from `ours/base/kustomization.yaml`, and
`kubectl -n ours delete deploy/minio svc/minio ingress/ours-storage pvc/minio-data`.

Preview what any kustomization renders without applying:

```bash
kubectl kustomize kubernetes/apps/personal-website/overlays/prod
```

## Why base/overlays when there's only prod?

The structure costs nothing now and pays off twice later: a `staging` overlay
becomes a 5-line directory, and when GitOps (Argo CD / Flux) arrives it points
at `overlays/prod` with zero restructuring.
