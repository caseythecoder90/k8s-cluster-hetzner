# Runbook — day-2 operations

## Health checks

```bash
kubectl get nodes -o wide
kubectl get pods -A | grep -v Running     # anything unhealthy
kubectl top nodes                          # needs metrics-server installed
ssh -i ~/.ssh/hetzner_k8s deploy@<cp-ip> "sudo systemctl status kubelet containerd --no-pager"
```

## OS patching

Security updates apply automatically (unattended-upgrades). For everything else:

```bash
cd ansible && ansible-playbook playbooks/01-base.yml   # runs dist-upgrade
```

Kernel updates need a reboot — one node at a time, worker first:

```bash
kubectl drain prod-worker-1 --ignore-daemonsets --delete-emptydir-data
ssh -i ~/.ssh/hetzner_k8s deploy@<worker-ip> sudo reboot
# wait for it: kubectl get nodes -w
kubectl uncordon prod-worker-1
# then the same for prod-cp-1 (apiserver is briefly down — apps keep serving)
```

## Kubernetes upgrades (minor version, e.g. 1.33 → 1.34)

k8s supports one minor hop at a time. Sequence (details: official
"Upgrading kubeadm clusters" doc):

1. Bump `kubernetes_version` in `ansible/group_vars/all.yml`
2. Re-run `playbooks/02-kube-prep.yml` (switches apt repo; packages still held)
3. On cp-1: `apt-mark unhold kubeadm && apt install kubeadm && kubeadm upgrade plan && kubeadm upgrade apply v1.34.x`
4. Drain cp-1, upgrade kubelet+kubectl, uncordon, re-hold
5. Worker: drain → `kubeadm upgrade node` → upgrade kubelet → uncordon → re-hold

## Scaling up

- **Bigger node**: Hetzner console → server → Rescale (CPU/RAM-only rescale is
  reversible; disk rescale is not). Update `terraform/variables.tf` to match,
  then `terraform plan` must show no changes.
- **More workers**: copy the worker block in `terraform/servers.tf` (or make it
  `count`-based), apply, add to inventory template, run playbooks 01/02/04.

## Certificates

kubeadm client certs expire after 1 year. Check / renew:

```bash
ssh deploy@<cp-ip> "sudo kubeadm certs check-expiration"
ssh deploy@<cp-ip> "sudo kubeadm certs renew all"   # then restart control plane pods
```

(A `kubeadm upgrade` also renews them — upgrading at least yearly covers this.)

## If a node dies

- Worker: `kubectl delete node prod-worker-1`, rebuild via
  `terraform taint hcloud_server.worker && terraform apply`, re-run playbooks 01/02/04.
- Control plane: single-CP cluster ⇒ the cluster state lives in etcd on that
  node. **Back up etcd** if you start caring:
  ```bash
  sudo ETCDCTL_API=3 etcdctl snapshot save /root/etcd-backup.db \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key
  ```
  Since everything is in Git, full rebuild (terraform + ansible + kubectl
  apply) is also a legitimate recovery strategy at this scale.

## Teardown (everything, permanently)

```bash
cd terraform && terraform destroy
```

## Common diagnostics

| Symptom | First moves |
|---|---|
| Node NotReady | `kubectl describe node X`; on node: `journalctl -u kubelet -f` |
| Pod Pending | `kubectl describe pod` — usually resources or taints |
| Pod CrashLoopBackOff | `kubectl logs --previous`; check probes hitting the right port |
| ImagePullBackOff | image name/tag typo, or missing imagePullSecret |
| DNS broken in pods | `kubectl -n kube-system get pods -l k8s-app=kube-dns`; restart CoreDNS |
| Calico issues | `kubectl -n calico-system get pods`; `kubectl describe installation default` |
