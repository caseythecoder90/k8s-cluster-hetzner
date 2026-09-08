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
