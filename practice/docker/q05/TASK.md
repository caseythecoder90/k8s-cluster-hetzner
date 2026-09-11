# q05 — push to a private registry, and get it back

A private registry is running at **localhost:5000** (no login required).
Source files are in `work/q05/`.

1. Build the image so that it can be pushed to that registry, as
   `ckad-hydra` version `v2`.
2. Push it.
3. Delete every local copy of the image, then pull it back from the registry
   and confirm it runs (it prints `hydra v2`).
