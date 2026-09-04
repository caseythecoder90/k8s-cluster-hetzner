# Q16 (topic: init containers, dependency ordering)

Namespace `atlas` has `atlas-db-svc` (port 5432) backed by a running pod.

Create a Deployment `atlas-web`, image `nginx:1-alpine`, 1 replica, that
**waits for the database to be reachable before starting**:

1. Add an `initContainer` named `wait-for-db`, image `busybox:1`
2. It must loop, checking `atlas-db-svc:5432` with `nc -z`, until the
   connection succeeds — only then does the init container exit and the
   main `nginx` container start
