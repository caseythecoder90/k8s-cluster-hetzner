# Q4 (topic: Endpoints exist and traffic still fails)

Team Hudson has the same complaint as team Amazon in Q1, but a different fault.
Service `hudson-web` in Namespace `hudson` fronts a healthy Deployment:
`kubectl -n hudson get endpoints hudson-web` lists both Pod IPs. Requests to
the Service still fail — and they fail *instantly*, with a connection refused,
not with a hang. The manifest is at `/course6/4/service.yaml`.

1. Find the fault and fix the **Service** so requests to its port `80` are
   served
2. Keep the Service's name, its type `ClusterIP` and its port `80`
3. Do not change the Deployment, the container, the container's port or the
   Pods' labels

Namespace `hudson` runs a busybox Deployment `probe` to test from.

> Target: 3 minutes. Q1 had no Endpoints. This one has Endpoints — so read the
> **port** they were written with, and compare it to the port nginx is really
> listening on.
