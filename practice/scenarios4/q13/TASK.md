# Q13 (topic: Kustomize generators)

Overlay `/course4/13/overlays/prod` deploys Deployment `lapis-app` into
Namespace `lapis`. Its Pod is stuck: the Deployment mounts a ConfigMap
`app-config` and reads a Secret `db-creds`, and neither exists.

Generate both from the overlay's kustomization:

1. ConfigMap `app-config` from the file `app.properties` in the overlay
   directory (key = the file name) plus the literal `LOG_LEVEL=warn`
2. Secret `db-creds` from the literals `username=lapis` and
   `password=ruby-lapis-42`
3. The Secret must be named exactly `db-creds`, without a hash suffix — an
   external tool reads it by that name. The ConfigMap may keep its suffix

Apply the overlay so that the Pod runs.
