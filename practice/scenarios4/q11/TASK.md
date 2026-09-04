# Q11 (topic: Kustomize strategic merge patch)

The prod overlay `/course4/11/overlays/prod` is deployed in Namespace
`agate`. Ops asks for resource settings and a readiness check on container
`api` of Deployment `agate-api`:

- requests: cpu `50m`, memory `32Mi`; limits: memory `64Mi`
- a readinessProbe doing an HTTP GET on path `/` port `80`, every `5`
  seconds

Implement this as a **strategic merge patch** in its own file
`/course4/11/overlays/prod/patch-resources.yaml`, referenced from the
overlay's kustomization. Apply the overlay. The base must not change.
