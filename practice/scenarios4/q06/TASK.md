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
