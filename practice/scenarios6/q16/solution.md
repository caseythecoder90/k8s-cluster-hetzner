# Q16 solution

## Check the Service ports before you write a single line

```bash
k -n elbe get svc
# NAME   TYPE        CLUSTER-IP     PORT(S)
# api    ClusterIP   10.x.x.x       8080/TCP
# site   ClusterIP   10.x.x.x       80/TCP
```

`api` publishes **8080** and forwards to the container's 80. The Ingress
backend must say `8080`.

## Start from the generator, then edit

`kubectl create ingress` handles one host/path pair per `--rule`, and the
syntax is `host/path=service:port`:

```bash
k -n elbe create ingress elbe-routes \
  --rule="shop.elbe.example.com/*=site:80" \
  --rule="shop.elbe.example.com/api*=api:8080" \
  --rule="api.elbe.example.com/*=api:8080" \
  $do > /course6/16/elbe-routes.yaml
```

The trailing `*` is what makes the generator emit `pathType: Prefix`; without
it you get `Exact`. Read the generated file, fix anything it got wrong
(`/*` renders as path `/`, which is what you want here), and apply:

```bash
vim /course6/16/elbe-routes.yaml
k apply -f /course6/16/elbe-routes.yaml
```

## The manifest

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: elbe-routes
  namespace: elbe
spec:
  rules:
    - host: shop.elbe.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: site
                port:
                  number: 80
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api
                port:
                  number: 8080          # the SERVICE port
    - host: api.elbe.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api
                port:
                  number: 8080
```

```bash
k -n elbe describe ingress elbe-routes
```

## There is no ingress controller in this lab — and that is fine

`kubectl get ingress` will show an empty `ADDRESS` column forever, and
`curl shop.elbe.example.com` reaches nothing. An **Ingress is only a set of
routing rules stored in the API server**; something has to read them and act
on them. That something is an ingress *controller* — ingress-nginx, Traefik,
HAProxy, a cloud load balancer — and none is installed here. The object is
still created, validated and stored exactly as it would be in a real cluster,
which is why `verify.sh` inspects the object and never fetches through it.

Two consequences worth internalising:

- **On the exam, "create an Ingress" is graded on the object.** If a cluster
  does have a controller, a `curl` is a nice extra confirmation, but the marks
  are in the spec.
- **`ADDRESS` being empty means "no controller has claimed this Ingress"**,
  not "your YAML is wrong". In a real cluster with a controller, an empty
  ADDRESS usually means your `ingressClassName` does not match any installed
  IngressClass.

In a cluster that does have a controller you would add:

```yaml
spec:
  ingressClassName: nginx      # must match an existing IngressClass
```

It is omitted here because there is no IngressClass to name.

## The three things that get marked wrong

1. **The backend port is the Service's port, not the pod's.** `api` is
   `8080 -> 80`; the container listens on 80 and nothing in the Ingress ever
   mentions 80. The Ingress talks to the Service, and the Service does the
   translation. Writing `number: 80` there produces an Ingress that a
   controller cannot route — and no error, because nothing validates that the
   port exists on the Service at creation time.

   (`port: {name: http}` is legal too, and matches the Service's *named*
   port — but the task asks for the number, and a name that does not exist on
   the Service fails just as silently.)

2. **`pathType` is required.** It has no default: leave it out and the API
   server rejects the object (`spec.rules[0].http.paths[0].pathType: Required
   value`). The three values:

   | `pathType` | matches |
   |---|---|
   | `Prefix` | path **elements** — `/api` matches `/api` and `/api/v1`, but not `/apifoo` |
   | `Exact` | that exact path and nothing else |
   | `ImplementationSpecific` | whatever the controller says; avoid on the exam |

   `Prefix` is what "route everything under this path" means, and it is the
   one to reach for by default.

3. **Host and path are two different discriminators, and both live in the
   same object.** One `rules` entry per **host**; the paths under that host's
   `http.paths` are what split by URL. A second `- host:` entry is a second
   virtual host. Piling all three paths under one host, or creating three
   separate Ingress objects, are the two usual mis-shapes.

## Ordering

Within one host, a controller matches the **longest** path first, not the
order you wrote them. So `/` and `/api` under `shop.elbe.example.com` do the
right thing regardless of which you list first: `/api/orders` goes to `api`,
`/anything-else` goes to `site`. Do not try to encode precedence by ordering
— it is not part of the spec.
