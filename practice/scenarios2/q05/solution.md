# Q5 solution

Both have imperative generators — no YAML needed:

```bash
k -n apollo create role apollo-pod-reader \
  --verb=get --verb=list --verb=watch --resource=pods

k -n apollo create rolebinding apollo-pod-reader-binding \
  --role=apollo-pod-reader --serviceaccount=apollo:apollo-reader
```

Verify exactly how the exam grades RBAC — with `auth can-i`, not by reading
YAML:

```bash
k auth can-i list pods -n apollo --as=system:serviceaccount:apollo:apollo-reader
k auth can-i delete pods -n apollo --as=system:serviceaccount:apollo:apollo-reader
```

The `--as=system:serviceaccount:<namespace>:<name>` syntax is worth
memorizing verbatim — it's how you impersonate any ServiceAccount to test
permissions without actually `exec`ing into a pod running as it.

Trap: `--resource=pods` (plural) not `pod`. Role/RoleBinding are
**namespaced** — for a permission that should apply cluster-wide, the
equivalents are `ClusterRole`/`ClusterRoleBinding`, created the same way with
`k create clusterrole` / `k create clusterrolebinding`.
