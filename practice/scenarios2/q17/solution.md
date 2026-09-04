# Q17 solution

```bash
k -n helios create deploy helios-batch --image=busybox:1 $do -- sleep 3600 > d.yaml
vim d.yaml
```

```yaml
    spec:
      tolerations:
      - key: dedicated
        operator: Equal
        value: helios
        effect: NoSchedule
      nodeSelector:
        kubernetes.io/hostname: lab-worker-1
      containers:
      - name: busybox
        ...
```

```bash
k apply -f d.yaml
k -n helios get pods -o wide     # NODE column should show lab-worker-1
```

The concept that trips people up: **taints and tolerations are a
one-directional filter, not a pin.** A taint on a node *repels* pods that
don't tolerate it. A toleration on a pod just says "I'm allowed to land
here" — it does **not** mean the scheduler will actually choose that node
over any other untainted one. To *require* a specific node, you need a
second, independent mechanism — `nodeSelector` (simple, exact match) or
`nodeAffinity` (more expressive matching) — alongside the toleration.

This pairing — taint the node, toleration + nodeSelector on the pod — is
exactly how "dedicated nodes" work in real clusters: taint a node pool so
*only* pods that explicitly opt in (toleration) and explicitly target it
(selector/affinity) can land there; everything else is naturally repelled.

Check the taint is really there first, if unsure: `k describe node
lab-worker-1 | grep Taints`.
