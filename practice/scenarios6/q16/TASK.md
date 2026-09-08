# Q16 (topic: Ingress — host and path routing)

Namespace `elbe` runs two Services:

| Service | Service port | targetPort |
|---|---|---|
| `site` | `80` | `80` |
| `api` | `8080` | `80` |

Team Elbe wants both published behind one Ingress.

1. Create an Ingress named `elbe-routes` in Namespace `elbe`, saved as
   `/course6/16/elbe-routes.yaml`, and apply it
2. Host `shop.elbe.example.com`:
   - path `/` → Service `site`
   - path `/api` → Service `api`
3. Host `api.elbe.example.com`:
   - path `/` → Service `api`
4. Every path uses `pathType: Prefix`, and every backend names its Service
   **port by number**
5. Exactly two `rules` entries and three paths in total — no others

**This lab has no ingress controller installed.** The Ingress will be created,
will show no `ADDRESS`, and nothing will serve on those hostnames. That is
expected and is not a mistake on your part. `verify.sh` checks the Ingress
*object* — its hosts, paths, pathTypes and backends — and never makes an HTTP
request through it.

> Target: 6 minutes. Two of the three backends point at the same Service, and
> the number you write next to it is not the port the container listens on.
