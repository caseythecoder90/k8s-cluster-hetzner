# 03 — Bootstrap the cluster (kubeadm + Calico)

## Playbook 03 — control plane

```bash
cd ansible
ansible-playbook playbooks/03-control-plane.yml
```

What it does (first run ~3-4 min):

1. **`kubeadm init`** with a config file (see
   `roles/control_plane/templates/kubeadm-config.yaml.j2`): API server
   advertises on the private IP, public IP added to cert SANs, pod subnet
   192.168.0.0/16, systemd cgroup driver.
2. **Calico** via the Tigera operator, VXLAN encapsulation. Until the CNI is
   running, the node reports NotReady — that's expected mid-play.
3. **kubeconfigs**: one for the deploy user on the server, one fetched to
   `ansible/kubeconfig/admin.conf` (gitignored) rewritten to the public IP.

## Playbook 04 — worker join

```bash
ansible-playbook playbooks/04-workers.yml
```

Generates a fresh join token on the control plane (tokens expire after 24h —
we never store them) and runs `kubeadm join` on the worker.

## kubectl from your workstation

```bash
# quick use
export KUBECONFIG=/mnt/c/Users/casey/Projects/k8s-cluster-hetzner/ansible/kubeconfig/admin.conf
kubectl get nodes -o wide

# or merge into ~/.kube/config permanently
mkdir -p ~/.kube && cp ansible/kubeconfig/admin.conf ~/.kube/config-hetzner-prod
echo 'export KUBECONFIG=~/.kube/config:~/.kube/config-hetzner-prod' >> ~/.bashrc
```

Windows-side kubectl: copy `ansible\kubeconfig\admin.conf` to
`C:\Users\casey\.kube\` and set `KUBECONFIG` accordingly.

## Expected healthy state

```
$ kubectl get nodes
NAME            STATUS   ROLES           AGE   VERSION
prod-cp-1       Ready    control-plane   10m   v1.33.x
prod-worker-1   Ready    <none>          5m    v1.33.x

$ kubectl get pods -A    # all Running, calico-* included
```

## Should apps run on the control plane too?

By default the control plane is tainted — apps schedule only to the worker.
With just two nodes you may eventually want both schedulable:

```bash
kubectl taint nodes prod-cp-1 node-role.kubernetes.io/control-plane:NoSchedule-
```

Recommendation: **keep the taint for now.** One CX33 worker (4 vCPU/8 GB) is
plenty for both apps, and an isolated control plane means a runaway app can't
starve etcd/apiserver. Remove it later if you need the capacity.

Next: [04 — Deploy workloads](04-deploy-workloads.md)
