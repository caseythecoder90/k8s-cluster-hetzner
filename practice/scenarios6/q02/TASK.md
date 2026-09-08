# Q2 (topic: NodePort — `port` vs `targetPort` vs `nodePort`)

Deployment `danube-web` in Namespace `danube` runs 2 nginx Pods labelled
`app=danube-web`, listening on container port `80`. Team Danube needs it
reachable from outside the cluster on a port they have already put in their
runbook.

Create a Service named `danube-web` in Namespace `danube`:

1. Type `NodePort`
2. Selects the `danube-web` Pods
3. Cluster-internal Service port `8080`
4. Traffic is delivered to the Pods on container port `80`
5. The node port is exactly `30602` — not one the cluster picks

Save the manifest as `/course6/2/service.yaml` and apply it. When it is right,
`curl http://10.10.1.10:30602` from the control plane returns the page, and so
does `http://<clusterIP>:8080` from a Pod inside the cluster. (This lab reaches
node ports on the node's **private** IP `10.10.1.10`, not `localhost`.)

> Target: 4 minutes. Three numbers, three different jobs, and only one of them
> belongs to the container. Say which is which out loud before you type them.
