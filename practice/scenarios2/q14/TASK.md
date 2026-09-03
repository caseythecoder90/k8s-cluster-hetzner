# Q14 (topics: StatefulSets, headless Services)

In Namespace `olympus`:

1. Create a **headless** Service `olympus-svc` (`clusterIP: None`) selecting
   `app=olympus`, port 80
2. Create a StatefulSet `olympus-app`, **3 replicas**, image `nginx:1-alpine`,
   using `olympus-svc` as its `serviceName`

Confirm each Pod gets its own stable DNS name:
`olympus-app-0.olympus-svc.olympus.svc.cluster.local` (and `-1`, `-2`)
should each resolve to that specific Pod's IP.
