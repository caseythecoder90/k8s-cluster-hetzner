# Q9 (topic: Kustomize basics)

A Kustomization for the Topaz app lives at `/course4/9/app` on the
control-plane host.

1. All its resources must be deployed into Namespace `topaz` (exists).
   Configure that inside the Kustomization, not with a kubectl flag
2. Save the fully rendered output of the Kustomization to
   `/course4/9/rendered.yaml`
3. Apply the Kustomization
4. Write the number of Kubernetes resources the Kustomization renders to
   `/course4/9/count`
