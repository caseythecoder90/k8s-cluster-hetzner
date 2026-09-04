# Q2 (topic: Helm install with values)

Team Beryl needs the internal API deployed:

1. Install chart `hk-charts/api` in chart version `2.1.0` (deliberately *not*
   the latest) as release `beryl-api` into Namespace `beryl`. The Namespace
   does not exist yet — have Helm create it.
2. Configure the release **via Helm values** so that:
   - the Deployment runs `3` replicas
   - the Service is of type `NodePort` using node port `30402`
   - the container has an environment variable `LOG_LEVEL` with value `debug`
3. Confirm the app answers on the node port, e.g. from the control-plane host:
   `curl http://10.10.1.10:30402`
