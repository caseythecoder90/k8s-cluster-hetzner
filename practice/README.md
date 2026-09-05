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
./practice/scripts/lab-down.sh          # add --yes to skip terraform's prompts
```

Use this instead of a bare `terraform destroy`. That command only tears down
the workspace you currently have selected, says nothing about the workspaces
you forgot, and reports success from Terraform state alone — so a resource
that drifted out of state stays up, and stays billed. `lab-down.sh` destroys
**every** workspace, then asks the Hetzner API what is actually still running
and exits non-zero if anything `lab-`-prefixed survived. It also clears the
leftovers that mislead you next session: the kubeconfig for a cluster that no
longer exists, and the host keys of IPs Hetzner has already recycled.

It never deletes through the API — Terraform is the only thing that destroys.

```bash
./practice/scripts/lab-down.sh --status   # what is up, for how long, what it cost
```

`--status` only reads the API, so it needs no Terraform and no state — run it
from any machine. Exit code is 0 when the lab is down and 2 when it is up,
which makes it usable from a shell prompt or a cron nag. It warns past
`LAB_MAX_HOURS` (default 8) and lists unmanaged strays — detached Volumes,
old snapshots, unassigned Primary IPs — which bill until you delete them by
hand and which Terraform can never clean up, because it never created them.

Nothing worth keeping lives on the cluster — scenarios re-create their own
state from `scenarios/` next session.

**Stopping a server does not stop the bill.** Hetzner charges for a server
existing, not running, and for Primary IPs even while unassigned. Destroy is
the only teardown that saves money.

## Scenarios

Each set holds one directory per exam question: `setup.sh` (pre-creates the
question's starting state), `TASK.md` (the assignment), `solution.md` (read
only after attempting), `verify.sh` where applicable.

Four sets so far, all runnable on the same cluster at once (each uses its own
`/courseN` paths and Namespace family). The two killer.sh rebuilds are
copyrighted material and stay **gitignored, local-only**; the two original
sets are committed:

| Set | What | Namespaces | In git? |
|---|---|---|---|
| `scenarios/` | killer.sh attempt 1, rebuilt | planets | no |
| `scenarios2/` | original set filling attempt 1's topic gaps | planets | yes |
| `scenarios3/` | killer.sh attempt 2, rebuilt | trees | no |
| `scenarios4/` | original set, **Helm + Kustomize only** (16 questions) | gemstones | yes |

Timed run: pick questions, run their `setup.sh`, start a timer, work in a
plain SSH session on the control plane like the real exam (not your cozy
local terminal).

## A second lab next to the first (optional)

The Terraform config is workspace-aware: every workspace other than
`default` gets its own state and its own names (`lab-<workspace>-cp-1`,
`hosts-<workspace>.yml`), so a second cluster can run beside the normal lab
without touching it.

```bash
cd practice/terraform
terraform workspace new hk            # creates AND selects it...
terraform workspace select default    # ...so switch back: a bare `terraform destroy` must keep meaning the normal lab
TF_WORKSPACE=hk terraform apply -var ipv6_enabled=false
cd ../ansible
ansible-playbook -i inventory/hosts-hk.yml playbooks/site.yml \
  -e ansible_user=root -e cluster_name=lab-hk -e kubeconfig_dest=$PWD/kubeconfig/admin-hk.conf
```

Then `LAB_WORKSPACE=hk ./setup-all.sh` in a scenario set, and
`TF_WORKSPACE=hk terraform destroy -var ipv6_enabled=false` when done.

**Account limits (checked 2026-09-03):** this Hetzner project allows 5 servers
and 8 Primary IPs. With prod (2 servers, 4 IPs) and the normal lab (2, 4)
running, a second lab does not fit — the apply fails with *server limit
reached* / *Primary IP limit exceeded*. Either request a limit increase in
the Hetzner Console (Limits), or destroy the normal lab first, in which case
you don't need a second workspace at all. `ipv6_enabled=false` exists because
each address family costs a Primary IP; nothing in the lab uses IPv6.

Hetzner recycles IPs, so a rebuilt cluster can come up on an address whose
old host key is still in `~/.ssh/known_hosts`. Clear it before Ansible:
`ssh-keygen -R <ip>` (and `-f ~/.ssh/known_hosts_lab` for the scenario
scripts' own file).
