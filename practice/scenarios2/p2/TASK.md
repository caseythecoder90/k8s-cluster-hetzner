# Preview Q2 (topic: Kustomize)

A base Kustomization exists at `/course2/p2/base` (Deployment `nike-web`,
Service `nike-svc`, namespace `nike`) on the control-plane host.

Create an overlay at `/course2/p2/overlay/prod` that, applied on top of the
base:

1. Sets **replicas to 3**
2. Adds a **common label** `env: production` to every resource
3. Changes the Deployment's image tag to `1.27-alpine`

Apply it with `kubectl apply -k /course2/p2/overlay/prod`.
