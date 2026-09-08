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
