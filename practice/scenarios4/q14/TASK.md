# Q14 (topic: Kustomize troubleshooting)

Someone broke the Kustomize setup at `/course4/14`:
`kubectl apply -k /course4/14/overlays/prod` fails.

Fix all problems, editing only Kustomization files. The Kubernetes
manifests (`deployment.yaml`, `service.yaml`) are correct and must not be
modified or renamed.

When you are done, the overlay must apply cleanly and deploy Deployment
`slate-web` with `2` replicas into Namespace `slate`, with the label
`team: slate` on every resource.
