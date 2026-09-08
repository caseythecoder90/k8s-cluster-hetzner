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
