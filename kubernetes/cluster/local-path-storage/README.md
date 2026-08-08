# local-path-provisioner

kubeadm ships no StorageClass — a PVC would sit Pending forever with nothing
to fulfill it. Rancher's local-path-provisioner satisfies PVCs with plain
directories on the node's disk (under /opt/local-path-provisioner).

Trade-off to understand: a local-path volume is bound to the node it was
created on. The postgres pod can only ever run on that node, and node loss =
data loss without backups (see docs/runbook.md for pg_dump backups; a Hetzner
Volume + CSI driver is the upgrade path if this ever matters more).
For a 2-node personal cluster this is the right simplicity/cost point.

## Install (once)

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.33/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

The patch marks it the *default* StorageClass so PVCs that don't name one
(like ours) use it automatically.

Verify: `kubectl get storageclass` → `local-path (default)`.
