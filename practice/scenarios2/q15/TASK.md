# Q15 (topic: Secrets as volumes)

Namespace `chronos` has an existing Secret `chronos-creds` (keys `username`,
`password`).

Create a Deployment `chronos-app`, 1 replica, image `nginx:1-alpine`,
container name `app`:

1. Mount `chronos-creds` as a **volume** at `/etc/creds`
2. The mounted files must be **owner-read-only** — set the volume's
   `defaultMode` to `0400`
