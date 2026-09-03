# Q13 (topic: static PersistentVolumes)

No dynamic provisioner this time — bind manually.

1. Create a PersistentVolume `dionysus-pv`:
   - `hostPath`: `/mnt/data/dionysus` (already exists on the control-plane
     host)
   - capacity `1Gi`, `accessModes: [ReadWriteOnce]`
   - `storageClassName: manual`
2. In Namespace `dionysus`, create a PersistentVolumeClaim `dionysus-pvc`
   requesting `1Gi`, `storageClassName: manual`, `ReadWriteOnce`
3. Confirm the PVC binds **directly** to that PV (no provisioner involved)
