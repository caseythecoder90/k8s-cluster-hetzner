# Q9 (topics: deployments, configmap volumes, resource limits)

In Namespace `ares` a single Pod `ares-report` runs (template at
`/course2/9/ares-report-pod.yaml`). An existing ConfigMap
`ares-report-config` holds a file `report.txt`.

1. Convert the Pod into a Deployment `ares-report` with **2 replicas**
2. Mount `ares-report-config` as a **volume** at `/etc/report` (read-only)
3. Add container resource **limits** (no requests needed): `cpu: 100m`,
   `memory: 64Mi`
4. Save the Deployment YAML at `/course2/9/ares-report-deployment.yaml`
5. Delete the original Pod once the Deployment's pods are running
