# Q8 (topic: readiness probes)

Deployment `hades-cache` in Namespace `hades` (Service `hades-cache-svc`
already points at it) warms up for a few seconds before it's ready — it
creates the file `/tmp/ready` once warm-up finishes.

Add a **readinessProbe** to the container:

1. `exec` handler checking that `/tmp/ready` exists
2. Check every **5 seconds** (`periodSeconds`)
3. Allow up to **3** consecutive failures before marking it not-ready
   (`failureThreshold`)

Confirm that once ready, `hades-cache-svc` actually has an endpoint.
