# Q16 (topic: Kustomize components)

`/course4/16` holds a base, a `dev` and a `prod` overlay (deployed into
Namespaces `obsidian-dev` and `obsidian`), and a reusable feature bundle at
`/course4/16/components/monitoring`.

Enable the monitoring component for **prod only**, then apply both overlays
so the cluster reflects it: in `obsidian`, Deployment `obsidian-app` gets the
component's `METRICS_ENABLED` environment variable and ConfigMap
`monitoring-config` exists; `obsidian-dev` stays without both.

Do not modify the base or the component.
