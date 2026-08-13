# CKAD practice cluster ("lab")

Disposable kubeadm cluster for exam practice, built from the same Ansible
roles as prod. 2× CX23 (~2¢/hour for the pair, hourly billing): **spin up for
a session, `terraform destroy` after.** A forgotten weekend costs ~$1.

Everything here is isolated from prod: separate Terraform state, separate
network (10.10.0.0/16), separate inventory, separate kubeconfig, resources
prefixed `lab-`.

## ⚠ Two-cluster safety

Your shell's defaults point at PROD (`ANSIBLE_CONFIG` and `KUBECONFIG` in
`~/.bashrc`). Every lab session starts by re-pointing them **in that shell**:

```bash
export ANSIBLE_CONFIG=/mnt/c/Users/casey/Projects/k8s-cluster-hetzner/practice/ansible/ansible.cfg
export KUBECONFIG=/mnt/c/Users/casey/Projects/k8s-cluster-hetzner/practice/ansible/kubeconfig/admin.conf
```

Habit that saves you: `kubectl config current-context` before anything —
`kubernetes-admin@lab` = safe to break things; `kubernetes-admin@prod` = STOP.

## Session start (~10 min to a ready cluster)

```bash
cd practice/terraform && terraform init && terraform apply   # ~1 min
cd ../ansible
ansible-playbook playbooks/site.yml -e ansible_user=root      # ~6-8 min
kubectl get nodes    # 2 nodes Ready (control plane untainted — pods land anywhere)
```

`site.yml` runs the same 01-04 as prod plus `05-lab-setup.yml`: control-plane
taint removed, helm installed, and exam-style shell setup for the deploy user
(`k` alias, completion, `$do` = `--dry-run=client -o yaml`).

## Session end

```bash
cd practice/terraform && terraform destroy
```

Nothing worth keeping lives on the cluster — scenarios re-create their own
state from `scenarios/` next session.

## Scenarios

`scenarios/` holds one directory per exam question: `setup.sh` (pre-creates
the question's starting state), `TASK.md` (the assignment), `solution.md`
(read only after attempting), `verify.sh` where applicable. The directory is
**gitignored** — killer.sh questions are copyrighted; they stay local-only.

Timed run: pick questions, run their `setup.sh`, start a timer, work in a
plain SSH session on the control plane like the real exam (not your cozy
local terminal).
