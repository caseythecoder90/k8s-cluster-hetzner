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
kubectl apply -k kubernetes/apps/personal-website/overlays/prod
kubectl apply -k kubernetes/apps/habit-tracker/overlays/prod
```

Preview what any kustomization renders without applying:

```bash
kubectl kustomize kubernetes/apps/personal-website/overlays/prod
```

## Why base/overlays when there's only prod?

The structure costs nothing now and pays off twice later: a `staging` overlay
becomes a 5-line directory, and when GitOps (Argo CD / Flux) arrives it points
at `overlays/prod` with zero restructuring.
