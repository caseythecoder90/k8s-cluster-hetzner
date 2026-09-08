# Exam Set 6 — all tasks (print/read this during a timed run)

16 questions on Services, NetworkPolicy and the two release patterns CKAD
builds from primitives. This is the Services & Networking domain — **~20% of
the exam**, the largest single slice after Application Deployment — so unlike
Sets 4 and 5 this one is worth treating as close to a real mock. Pace at
**~6 min/question**.

Calico enforces NetworkPolicy in this lab, so the policies you write really do
drop packets. Every policy question is graded on **behaviour, not YAML**: the
traffic you were told to allow must still flow, and the traffic you were told
to block must actually be blocked. A default-deny that blocks everything fails
just as hard as a policy that allows everything.

Two environment notes:

- **No ingress controller is installed here.** q16 grades the Ingress resource
  structurally — rules, hosts, paths, `pathType`, backend service names and
  ports. Nothing will serve on it. That is expected.
- **NodePorts are reached on the node's private IP** `10.10.1.10`, not
  `localhost`.

There is no `kubectl create networkpolicy` generator. Every policy on this set,
and on the exam, is hand-written YAML — which is the whole reason to drill it.

---

# Q1 (topic: a Service that selects nothing)

Team Amazon says `amazon-web` in Namespace `amazon` is "deployed but dead".
Both Pods of Deployment `amazon-web` are Running and Ready, the Service exists
and has a ClusterIP, and every request to it fails. The Service manifest is at
`/course6/1/service.yaml`.

1. Diagnose it — begin with `kubectl -n amazon get endpoints amazon-web`
2. Fix the **Service** so that it selects the Deployment's Pods
3. The Service keeps its name `amazon-web`, type `ClusterIP` and port `80`

Do not change the Deployment, its Pod template or its Pod labels — the Pods are
correct, the Service is not. Namespace `amazon` also runs a busybox Deployment
`probe` you can `exec` into to test.

> Target: 3 minutes. A Service is bolted to Pods by labels and by nothing else,
> so empty Endpoints is never a Pod problem.

---

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

---

# Q3 (topic: a named `targetPort`, and a second port on the same Service)

Deployment `ganges-web` in Namespace `ganges` runs 2 Pods labelled
`app=ganges-web`. Its container listens on two ports, and the Pod spec names
them:

```yaml
ports:
  - name: http
    containerPort: 80
  - name: metrics
    containerPort: 9113
```

Create one ClusterIP Service `ganges-web` in Namespace `ganges` fronting both:

1. Selects the `ganges-web` Pods
2. A Service port `80` called `http`, whose `targetPort` is the container
   port's **name** `http` — the number `80` must not appear as the targetPort
3. A Service port `9113` called `metrics`, reaching container port `9113`

Save it as `/course6/3/service.yaml` and apply it. Both ports must actually
serve: `http://<clusterIP>:80` returns `ganges-web`, `http://<clusterIP>:9113`
returns `ganges-metrics`.

> Target: 4 minutes. The second port is where this one bites — a field that is
> optional on a single-port Service becomes mandatory the moment there are two,
> and the API server's error message names the field but not the reason.

---

# Q4 (topic: Endpoints exist and traffic still fails)

Team Hudson has the same complaint as team Amazon in Q1, but a different fault.
Service `hudson-web` in Namespace `hudson` fronts a healthy Deployment:
`kubectl -n hudson get endpoints hudson-web` lists both Pod IPs. Requests to
the Service still fail — and they fail *instantly*, with a connection refused,
not with a hang. The manifest is at `/course6/4/service.yaml`.

1. Find the fault and fix the **Service** so requests to its port `80` are
   served
2. Keep the Service's name, its type `ClusterIP` and its port `80`
3. Do not change the Deployment, the container, the container's port or the
   Pods' labels

Namespace `hudson` runs a busybox Deployment `probe` to test from.

> Target: 3 minutes. Q1 had no Endpoints. This one has Endpoints — so read the
> **port** they were written with, and compare it to the port nginx is really
> listening on.

---

# Q5 (topic: default-deny ingress for a whole Namespace)

Namespace `indus` is being locked down. Nothing may open a connection **to** any
Pod in it — not from another Namespace, and not from another Pod inside `indus`
either. The Pods must keep full outbound access, DNS above all: whatever you
write must not cost them name resolution.

Namespace `indus` runs `indus-web` (nginx, container port 80, labels
`app=indus-web`) and a busybox `indus-client` (labels `app=indus-client`).

1. Write a NetworkPolicy named `default-deny-ingress` in Namespace `indus`
2. It must select **every** Pod in the Namespace, present and future — not a
   list of the two that happen to exist today
3. It must deny all ingress to them and allow no exceptions
4. It must leave egress completely unrestricted

Save it as `/course6/5/policy.yaml` and apply it. Afterwards `indus-client`
must fail to reach `indus-web`, and must still resolve `kubernetes.default`.

> Target: 3 minutes. The whole spec is four lines and there are no rules in it
> at all — but the direction it denies is set by a field people leave out,
> and adding one word too many to that field takes DNS down with it.

---

# Q6 (topic: allow one label, on one port)

Namespace `jordan` runs `jordan-api` (labels `app=jordan-api`). Its container
listens on **two** ports: `8080` serves the application, `9090` serves an admin
endpoint that should never have been exposed. Service `jordan-api` publishes
both:

| Service port | goes to container port |
|---|---|
| `80` | `8080` |
| `9090` | `9090` |

Two busybox clients share the Namespace: Deployment `frontend` (labels
`app=frontend,role=frontend`) and Deployment `batch` (labels
`app=batch,role=batch`). Today both can reach both ports.

Write a NetworkPolicy named `allow-frontend` in Namespace `jordan` so that:

1. Only Pods labelled `role=frontend` may open connections to the `jordan-api`
   Pods
2. They may reach the **application** port only — the admin port must be closed
   to everyone, `frontend` included
3. Everything else keeps working: do not edit the Deployment, the Service or
   the clients, and do not delete the Service's admin port

Save it as `/course6/6/policy.yaml` and apply it.

> Target: 5 minutes. The port number you put in the policy is not the port
> number you curl — a NetworkPolicy has never heard of a Service.

---

# Q7 (topic: `namespaceSelector` and the automatic Namespace label)

`mekong-db` (labels `app=mekong-db`, nginx on container port `80`) runs in
Namespace `mekong`. Three busybox clients want to talk to it, two of them
labelled identically:

| Namespace | Deployment | Pod labels |
|---|---|---|
| `nile` | `nile-client` | `app=nile-client,role=client` |
| `nile` | `nile-batch` | `app=nile-batch,role=batch` |
| `mekong` | `mekong-client` | `app=mekong-client,role=client` |

Only Namespace `nile` is trusted. Write a NetworkPolicy named `allow-from-nile`
in Namespace `mekong` so that:

1. **Any** Pod running in Namespace `nile` may reach the `mekong-db` Pods on
   port `80` — `nile-batch` as much as `nile-client`
2. Nothing else may, including `mekong-client`, whose labels are identical to
   `nile-client`'s
3. Select `nile` by the label Kubernetes puts on every Namespace for you. You
   may not add labels to either Namespace.

Save it as `/course6/7/policy.yaml` and apply it.

> Target: 5 minutes. A `podSelector` inside a `from:` block only ever looks in
> the policy's own Namespace — which is precisely the Namespace you are trying
> to keep out.

---

# Q8 (topic: AND vs OR in a `from:` block — the dash is the operator)

`oder-api` (labels `app=oder-api`, nginx on container port `80`) runs in
Namespace `oder`. Three busybox clients can currently reach it:

| Namespace | Deployment | Pod labels | Must end up |
|---|---|---|---|
| `rhine` | `rhine-web` | `app=rhine-web,role=web` | **allowed** |
| `rhine` | `rhine-batch` | `app=rhine-batch,role=batch` | **blocked** |
| `oder` | `oder-web` | `app=oder-web,role=web` | **blocked** |

Write a NetworkPolicy named `allow-rhine-web` in Namespace `oder` that lets
**only Pods labelled `role=web` that are running in Namespace `rhine`** reach
the `oder-api` Pods on port `80`.

1. `rhine-batch` is in the right Namespace with the wrong label — it must be
   blocked
2. `oder-web` has the right label in the wrong Namespace — it must be blocked
3. Select `rhine` by the label Kubernetes sets on every Namespace; do not add
   Namespace labels of your own

Save it as `/course6/8/policy.yaml` and apply it.

> Target: 5 minutes. Both selectors go inside the same `from:` block. Whether
> that block means "and" or "or" comes down to one character — and one of the
> two spellings lets both of the Pods above straight in.

---

# Q9 (topic: egress NetworkPolicy — and keeping DNS alive)

Namespace `seine` runs two backends behind Services `payments` and `analytics`
(both `:80`), plus two client Deployments, `checkout` (pods labelled
`app: checkout`) and `audit`. Right now everything can reach everything.

Security wants `checkout` locked down on the way **out**.

1. Create a NetworkPolicy named `checkout-egress` in Namespace `seine`,
   saved as `/course6/9/egress.yaml`, and apply it
2. It must attach to the `checkout` pods only (`app: checkout`) and govern
   **Egress only** — `Ingress` must not appear in `policyTypes`
3. `checkout` may open TCP `:80` to the `payments` pods. It must **not** be
   able to reach `analytics`
4. `checkout` must still be able to resolve Service names — it will be tested
   with `http://payments.seine.svc.cluster.local`, by **name**, not by IP
5. `audit` is not selected by this policy and must keep working exactly as it
   does now

Do not change the Deployments or the Services.

> Target: 8 minutes. The moment `Egress` appears in `policyTypes` the pod
> loses something it was never told it had — and the failure looks nothing
> like a firewall error.

---

# Q10 (topic: `ipBlock` with `except:`)

Namespace `thames` runs a Service `vault` on `:80` and two clients, `alpha`
and `beta`. Both can reach `vault` today. Security has quarantined one address
and wants it kept off `vault` while the rest of the pod network keeps its
access.

The addresses are in `/course6/10/peers.txt` — read them from there, do not
guess them.

1. Create a NetworkPolicy named `vault-ingress` in Namespace `thames`, saved
   as `/course6/10/vault-ingress.yaml`, and apply it
2. It attaches to the `vault` pods (`app: vault`) and governs **Ingress only**
3. It admits TCP `:80` from the whole `pod-network-cidr` in that file,
   **except** the quarantined address
4. It must express the peers as a **CIDR** — this task is about `ipBlock`.
   No `podSelector` and no `namespaceSelector` anywhere in the rule

Afterwards `alpha` must still reach `vault` and `beta` must not.

Do not change the Deployments or the Service, and do not delete or re-create
any Pod (the addresses in the file would go stale).

> Target: 7 minutes. `except:` is not a sibling of `from:` — check twice where
> it hangs, and remember what an `except` entry has to be relative to `cidr`.

---

# Q11 (topic: one NetworkPolicy governing both directions)

Namespace `tiber` runs three Services on `:80` — `api`, `logs` and `billing` —
plus two clients, `frontend` and `scanner`. Every pod carries an `app` label
equal to its Deployment name. Nothing is restricted yet.

Team Tiber wants `api` fenced in on **both** sides, with a **single**
NetworkPolicy.

1. Create one NetworkPolicy named `api-fence` in Namespace `tiber`, saved as
   `/course6/11/api-fence.yaml`, and apply it. It must be the only
   NetworkPolicy in the Namespace
2. It attaches to the `api` pods (`app: api`) and its `policyTypes` must list
   **both** `Ingress` and `Egress`
3. Inbound: only the `frontend` pods may open TCP `:80` on `api`. `scanner`
   must not get in
4. Outbound: `api` may open TCP `:80` to the `logs` pods, and nothing else —
   it must not be able to reach `billing`
5. `frontend`, `scanner`, `logs` and `billing` are not selected by this policy
   and must keep working exactly as they do now

Everything here is probed by ClusterIP, so no DNS rule is needed. Do not
change the Deployments or the Services.

> Target: 7 minutes. `policyTypes` is a declaration, not a summary — naming a
> direction there commits you to writing the rules for it.

---

# Q12 (topic: blue/green cutover)

Namespace `volga` is mid blue/green release. Deployment `checkout-blue` (3
replicas, pods labelled `track: blue`) serves every request through Service
`checkout`. Deployment `checkout-green` (3 replicas, pods labelled
`track: green`) is fully deployed and taking no traffic. A copy of the live
Service is at `/course6/12/checkout-svc.yaml`.

Green has passed validation. Cut over.

1. Make Service `checkout` send **100%** of its traffic to the green pods, in
   one step. Its name, type, port and target port must not change
2. Leave `checkout-blue` running and untouched — 3 ready replicas, still
   serving `blue-v1` — so the release can be rolled back instantly

Do not scale, delete, edit or restart either Deployment. Deployment
`checkout-green` must also stay at 3 replicas.

You can watch the result with:

```bash
CIP=$(kubectl -n volga get svc checkout -o jsonpath='{.spec.clusterIP}')
kubectl -n volga exec deploy/probe -- sh -c "for i in 1 2 3 4 5 6 7 8 9 10; do wget -qO- $CIP; done"
```

> Target: 4 minutes. There is no `strategy.type` for this, and the object you
> change is not a Deployment.

---

# Q13 (topic: blue/green — validate, cut over, roll back)

Namespace `yangtze` runs the live Service `orders` (ClusterIP, `:80`), backed
by `orders-blue` (2 replicas, `track: blue`, serving `orders-v1`).
`orders-green` (2 replicas, `track: green`, serving `orders-v2`) is deployed
and taking no traffic. Client `probe` is there to fetch from.

Run the release end to end. Green turns out to be bad, so you will also back
it out.

1. **Validate green with no production traffic.** Create a second Service
   `orders-test` in `yangtze` — ClusterIP, port `80`, targetPort `80` — that
   selects the **green** pods only. Confirm it answers `orders-v2` while
   `orders` is still answering `orders-v1`
2. **Cut over.** Point Service `orders` at green
3. **Record the cutover.** While green is live on `orders`, save the Service's
   selector to `/course6/13/cutover.txt`:

   ```bash
   kubectl -n yangtze get svc orders -o jsonpath='{.spec.selector}' > /course6/13/cutover.txt
   ```

4. **Roll back.** Green is misbehaving. Put Service `orders` back on blue

End state: `orders` serves `orders-v1`, `orders-test` still serves
`orders-v2`, both Deployments still running at 2 ready replicas each, and
`cutover.txt` proving green was live.

Do not scale, edit or delete either Deployment at any point.

> Target: 8 minutes. Steps 2 and 4 are the same operation, and the reason step
> 4 takes seconds instead of minutes is something you must deliberately *not*
> do in between.

---

# Q14 (topic: canary via shared label + pod ratio)

Namespace `zambezi` serves shop traffic through Service `shop` (ClusterIP,
`:80`). Deployment `shop-primary` runs 4 replicas of `shop-v1`; its pods carry
`tier: shop` and `version: v1`, and the Service selects `tier: shop`. Client
`probe` is there to fetch from.

A canary manifest for `shop-v2` is waiting at `/course6/14/shop-canary.yaml`.
Put it into the rotation.

1. Edit `/course6/14/shop-canary.yaml` so that its pods are picked up by
   Service `shop`. Do not change the Service, and do not change the canary's
   own `spec.selector` — `shop-canary` must keep owning only its own pods
2. Apply it
3. Set the replica counts on `shop-primary` and `shop-canary` so that
   **roughly 25%** of requests land on the canary and there are **exactly 8**
   pods behind the Service in total
4. Both Deployments must end up fully ready, and requests to `shop` must be
   answered by **both** `shop-v1` and `shop-v2`

Do not touch Service `shop` — its selector must still be exactly `tier: shop`.

> Target: 6 minutes. The Service selector is already correct and stays that
> way; the canary manifest as written would come up perfectly healthy and take
> zero traffic.

---

# Q15 (topic: promoting a canary)

Namespace `congo` has been running a canary for an hour. Service `feed`
(ClusterIP, `:80`) selects `tier: feed`, which is carried by the pods of both
Deployments:

- `feed-primary` — 3 replicas, `version: v1`, serving `feed-v1`
- `feed-canary` — 1 replica, `version: v2`, serving `feed-v2`

The canary is clean. Promote it. A copy of the canary's manifest is at
`/course6/15/feed-canary.yaml`.

1. Roll `feed-primary` onto the new version: its pods must serve `feed-v2` and
   be labelled `version: v2`. (In this lab the version is baked into the
   container's `command` — copy it from `/course6/15/feed-canary.yaml`.) Its
   pods must keep `tier: feed`
2. Scale `feed-primary` to `4` replicas, so total capacity is unchanged once
   the canary is gone
3. Delete Deployment `feed-canary`
4. Do not touch Service `feed`. Its selector must still be exactly
   `tier: feed`, and it must have had backing pods throughout

End state: `feed-primary` alone, 4 ready replicas, every response `feed-v2`,
`feed-canary` gone, Service `feed` never edited.

> Target: 6 minutes. One label on the primary's pod template is doing all the
> work here — drop it while you are editing and the Service goes dark in the
> middle of the rollout.

---

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

