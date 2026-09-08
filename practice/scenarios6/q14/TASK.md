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
