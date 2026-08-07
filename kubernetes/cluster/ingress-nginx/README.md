# ingress-nginx

Routes HTTP/HTTPS from the internet to Services, based on Ingress resources.

## Install (once, after the cluster is up)

We have no cloud LoadBalancer (a Hetzner LB is ~$6/mo — skip for now), so the
controller binds ports 80/443 directly on the worker node via hostPort. DNS
A-records for your domains point at the worker's public IP.

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml
```

Then patch the controller to use hostPorts and run on the worker:

```bash
kubectl -n ingress-nginx patch deployment ingress-nginx-controller --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/ports/0/hostPort","value":80},
  {"op":"add","path":"/spec/template/spec/containers/0/ports/1/hostPort","value":443}
]'
```

Verify: `curl http://<worker-public-ip>` should return a 404 from nginx
(no routes yet — that's success).

## TLS

Add cert-manager + Let's Encrypt once the first app is serving:
https://cert-manager.io/docs/installation/

## Later

Pin a specific ingress-nginx version and vendor the manifest into this
directory (or move to Helm/GitOps) instead of applying from `main`.
