# q07 — stop rebuilding what didn't change

Every time anyone touches `app.sh` in `work/q07/`, the build reinstalls `curl`.
Fix that.

1. Reorder the Dockerfile so a change to `app.sh` no longer invalidates the
   `apk add` layer.
2. Prove it. Build it as `ckad-q07:v1`, edit `app.sh` (change the version it
   echoes), build again — and save the **second** build's output to
   `work/q07/build2.log`. The `apk add` step must show as cached in that log.
