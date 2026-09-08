# Q6 (topic: strategic merge on a keyed list — edit, add, delete)

Deployment `solder` at `/course5/6/base` runs three containers: `web`,
`cache` and `legacy`. Team Tin is retiring the `legacy` container and adding
a log shipper.

Using **one strategic merge patch** (strategic merge, not JSON 6902) in the
overlay `/course5/6/overlays/prod`:

1. Container `web` runs image `nginx:1.27-alpine` — its port and resources
   must survive
2. A new container `shipper` is added: image `busybox:1`, command
   `sh -c "sleep 86400"`
3. Container `legacy` is gone
4. Container `cache` is untouched

Apply the overlay. All three remaining containers must be Ready. Do not
modify the base.

> Target: 5 minutes. All three moves live in the same `containers:` list, and
> the list is matched by one field — but only two of the three moves are
> spelled by simply naming what you want.
