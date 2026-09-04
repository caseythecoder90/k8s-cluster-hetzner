# Q7 (topic: Helm values file, debugging a release)

Release `quartz-api` in Namespace `quartz` was installed from
`hk-charts/api` version `2.2.0` with the values file
`/course4/7/values.yaml`, but its Pods never became ready.

1. Find the cause
2. Fix it in `/course4/7/values.yaml` — the file must stay the single source
   of truth for this release, so do not use `--set`, and keep everything else
   in the file as it is
3. Apply the fix to the release so that all its Pods are running
