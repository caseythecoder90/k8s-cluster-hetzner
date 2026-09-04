# Q17 (topic: taints and tolerations)

Node `lab-worker-1` has been tainted `dedicated=helios:NoSchedule`.

Create a Deployment `helios-batch` in Namespace `helios`, image `busybox:1`,
command `sleep 3600`, **1 replica**, that:

1. **Tolerates** the `dedicated=helios:NoSchedule` taint
2. Is **guaranteed to land on `lab-worker-1`** specifically (a toleration
   alone only *allows* scheduling there — it doesn't *require* it)
