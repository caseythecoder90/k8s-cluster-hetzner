# Q3 (topic: Helm upgrade)

Release `coral-web` in Namespace `coral` was installed from chart
`hk-charts/nginx` some time ago, with custom values.

1. Upgrade the release to the newest chart version available in the repo
2. As part of the same upgrade, change the image tag to `1.27-alpine`
3. The replica count and the node port the release was originally installed
   with must stay exactly as they are — the team relies on them
4. Write the revision number the release has after your upgrade to
   `/course4/3/revision`
