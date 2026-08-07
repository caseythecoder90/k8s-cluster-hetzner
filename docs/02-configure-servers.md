# 02 — Configure servers (Ansible)

Two playbooks prepare the OS on both nodes. Run from `ansible/`.

## Playbook 01 — base

Creates the `deploy` user (SSH key + passwordless sudo), disables root login
and password auth entirely, enables fail2ban and unattended security updates.

```bash
cd ansible
ansible-playbook playbooks/01-base.yml -e ansible_user=root
```

The `-e ansible_user=root` matters **only this first time**: fresh servers
have no deploy user yet. After this run, root SSH is dead and every later
command connects as `deploy` (the inventory default).

Verify the hardening took:

```bash
ssh -i ~/.ssh/hetzner_k8s deploy@<cp-public-ip> whoami   # → deploy
ssh -i ~/.ssh/hetzner_k8s root@<cp-public-ip>            # → Permission denied ✔
```

## Playbook 02 — kubernetes prep

Everything kubeadm's preflight checks demand, on both nodes: swap off, kernel
modules (`overlay`, `br_netfilter`), sysctls (bridged traffic → iptables, IP
forwarding), containerd with systemd cgroups, and kubeadm/kubelet/kubectl
v1.33 from pkgs.k8s.io (apt-held so nothing upgrades them behind your back).

```bash
ansible-playbook playbooks/02-kube-prep.yml
```

Both playbooks are idempotent — re-running is always safe and is the way to
verify config drift (everything should report `ok`, nothing `changed`).

Next: [03 — Bootstrap the cluster](03-bootstrap-cluster.md)
