# Decision log

Why things are the way they are. Newest at the bottom.

| # | Decision | Alternatives considered | Rationale |
|---|---|---|---|
| 1 | **Hetzner Cloud, Nuremberg (nbg1)** | US locations (started there, deleted) | Cost-Optimized CX plans + ARM only exist in EU; US only offers pricier CPX. Latency to US visitors acceptable for personal projects. |
| 2 | **2× CX33** (4 vCPU/8 GB each, ~$19/mo total) | 2× CX23, CX33+CX23 mix, CAX21 ARM | kubeadm requires ≥2 vCPU on control plane; CX33 gives real headroom for ~$4/mo more per node. "Limited availability" = provisioning stock only; running servers are unaffected. Grabbed while in stock. |
| 3 | **x86 (CX) over ARM (CAX)** | CAX21 was cheaper per-perf pre-2026-pricing | Zero container-image friction: own apps build on default x86 CI. ARM would require buildx/multi-arch pipelines while also learning k8s. In USD billing CX33 is cheaper than CAX21 anyway. |
| 4 | **vanilla kubeadm** | k3s (recommended for the hardware), k0s | Learning value: this cluster doubles as kubeadm practice; a separate cluster exists for cert experimentation. Overhead (~1.5 GB on CP) acceptable on 8 GB nodes. |
| 5 | **Ubuntu 24.04 LTS** | 26.04 (console default) | k8s package/containerd support lags brand-new Ubuntu releases; LTS until 26.04.1+. |
| 6 | **Ansible for config** | cloud-init, bash scripts | Idempotent, re-runnable, self-documenting; industry-standard skill. cloud-init only runs once. |
| 7 | **Calico CNI, VXLAN** | Cilium, Flannel | User choice; full NetworkPolicy support, CKA-adjacent. VXLAN over IPIP for reliability on cloud network fabrics. |
| 8 | **Kustomize + kubectl, GitOps later** | Argo CD / Flux now | Fewest moving parts while learning. Tree structured (base/overlays) so Argo/Flux can point at it later unchanged. |
| 9 | **No Hetzner Load Balancer** | LB (~$6/mo) | ingress-nginx with hostPort 80/443 on the worker + DNS A record is fine for personal scale. LB is the upgrade path for multi-node HA ingress. |
| 10 | **Control plane stays tainted** | Schedule apps on both nodes | Isolation: runaway app can't starve etcd/apiserver. Revisit if capacity gets tight. |
| 11 | **Private network for all cluster traffic** | Public IPs + firewall | etcd/kubelet/CNI never exposed; Hetzner firewall only filters public interfaces anyway. |
| 12 | **Local Terraform state** | Remote state (S3, TF Cloud) | Single operator, simplest start. Revisit if a second machine/operator appears. |
