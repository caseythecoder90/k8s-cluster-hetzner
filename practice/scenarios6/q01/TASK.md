# Q1 (topic: a Service that selects nothing)

Team Amazon says `amazon-web` in Namespace `amazon` is "deployed but dead".
Both Pods of Deployment `amazon-web` are Running and Ready, the Service exists
and has a ClusterIP, and every request to it fails. The Service manifest is at
`/course6/1/service.yaml`.

1. Diagnose it — begin with `kubectl -n amazon get endpoints amazon-web`
2. Fix the **Service** so that it selects the Deployment's Pods
3. The Service keeps its name `amazon-web`, type `ClusterIP` and port `80`

Do not change the Deployment, its Pod template or its Pod labels — the Pods are
correct, the Service is not. Namespace `amazon` also runs a busybox Deployment
`probe` you can `exec` into to test.

> Target: 3 minutes. A Service is bolted to Pods by labels and by nothing else,
> so empty Endpoints is never a Pod problem.
