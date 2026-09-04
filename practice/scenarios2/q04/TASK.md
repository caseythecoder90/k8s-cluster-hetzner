# Q4 (topics: deployments, services, canary releases)

Namespace `hermes` runs `hermes-stable` (4 replicas) behind Service
`hermes-svc`, which selects on `app=hermes` only (both tracks match).
`hermes-canary` exists with 0 replicas.

Roll out a canary:

1. Update `hermes-canary`'s image to `nginx:1.31-alpine`
2. Scale `hermes-canary` to **1 replica** (roughly 20% of traffic, since the
   Service selects both tracks by `app` alone)
3. Do **not** change `hermes-svc`'s selector — canary traffic-splitting here
   works entirely through the shared label
