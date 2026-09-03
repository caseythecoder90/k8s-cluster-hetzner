# Preview Q1 (topic: Helm)

A Helm chart is provided at `/course2/p1/iris-chart` on the control-plane
host.

1. Install it into Namespace `iris` as release **`iris-web`**, overriding
   `replicaCount` to **2**
2. Then **upgrade** the same release, changing `image.tag` to `1.27-alpine`
   (keep `replicaCount` at 2)
3. Confirm the release history shows **2 revisions**
