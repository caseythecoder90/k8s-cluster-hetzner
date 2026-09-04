# Q13 solution

No generator for PV — write it from the docs skeleton:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: dionysus-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  hostPath:
    path: /mnt/data/dionysus
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dionysus-pvc
  namespace: dionysus
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

```bash
k apply -f pv.yaml -f pvc.yaml
k get pv dionysus-pv
k -n dionysus get pvc dionysus-pvc
```

Both should show `Bound` immediately — no provisioner needed, because
`storageClassName: manual` matches on **both** objects and there's no
provisioner registered for that name, so Kubernetes falls back to its oldest
mechanism: matching an unbound PVC to an unbound PV by capacity, access mode,
and storage class name alone. This is the model that predates dynamic
provisioning entirely — worth understanding since it's what q13 in Exam Set 1
(`../../scenarios/q13`) deliberately leaves *unbound*, to contrast "declared
provisioner that doesn't exist" against this "no provisioner needed at all."
