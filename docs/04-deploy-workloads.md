# 04 — Deploy workloads (Kustomize)

> Written before the migration as the generic Kustomize workflow. The order
> that was actually followed, with the real namespaces (`personal-website`,
> `grindtrack`), secrets and databases, is [05-app-migration.md](05-app-migration.md).

## Foundations

```bash
kubectl apply -k kubernetes/cluster/namespaces
```

Install ingress-nginx: follow
[kubernetes/cluster/ingress-nginx/README.md](../kubernetes/cluster/ingress-nginx/README.md).

## DNS

Point A records at the **worker's public IP** (that's where ingress-nginx
binds 80/443):

```
yourdomain.com        A   <worker-public-ip>
track.yourdomain.com  A   <worker-public-ip>
```

## Migrating your apps

Per app, in `kubernetes/apps/<app>/`:

1. **Image**: replace the `nginx:1.27-alpine` placeholder in
   `base/deployment.yaml` with your real image. Private registry (e.g. ghcr.io
   private) needs an `imagePullSecret`:
   ```bash
   kubectl -n apps create secret docker-registry ghcr-pull \
     --docker-server=ghcr.io --docker-username=caseythecoder90 \
     --docker-password=<a-github-PAT-with-read:packages>
   ```
   then `imagePullSecrets: [{name: ghcr-pull}]` in the pod spec.
2. **Port + health endpoints** in the probes.
3. **Host** in `base/ingress.yaml`.
4. **Config/secrets**: non-secret config → ConfigMap in the overlay; secrets →
   `kubectl create secret` by hand for now (Sealed Secrets or SOPS later —
   never commit raw Secret manifests).
5. Apply:
   ```bash
   kubectl apply -k kubernetes/apps/personal-website/overlays/prod
   kubectl get pods -n apps -w
   ```

## Databases

GrindTrack uses Postgres. Options, in order of pragmatism:

1. **Managed elsewhere** (keep whatever it uses today) — zero cluster risk.
2. **In-cluster** with a PVC on `local-path` storage — fine for personal
   scale; back up with `pg_dump` CronJob to object storage.
3. CloudNativePG operator — the proper way, more moving parts.

Note: bare kubeadm has **no default StorageClass**. For simple node-local
volumes install Rancher's local-path-provisioner:

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## Rollout cheat-sheet

```bash
kubectl -n apps rollout status deploy/personal-website
kubectl -n apps logs deploy/personal-website -f
kubectl -n apps rollout undo deploy/personal-website   # rollback
kubectl kustomize kubernetes/apps/grindtrack/overlays/prod   # dry-render
```
