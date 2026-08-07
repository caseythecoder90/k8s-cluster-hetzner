# 01 — Provision infrastructure (Terraform)

Creates in Hetzner project: private network, firewall, SSH key, and the two
CX33 servers in Nuremberg. Cost from this point: ~$19/mo.

## What gets created

| Resource | Name | Notes |
|---|---|---|
| Network | `prod-net` | 10.0.0.0/16, subnet 10.0.1.0/24 |
| Firewall | `prod-fw` | allows 22, 6443, 80, 443, ICMP on public IPs |
| SSH key | `prod-admin` | your `hetzner_k8s.pub`, injected as root's key |
| Server | `prod-cp-1` | CX33, private IP 10.0.1.10 |
| Server | `prod-worker-1` | CX33, private IP 10.0.1.20 |
| File (local) | `ansible/inventory/hosts.yml` | generated inventory with live IPs |

## Run it

```bash
cd terraform
terraform init      # downloads providers (first time only)
terraform plan      # review: should say "6 to add"
terraform apply     # type 'yes'
```

Takes ~1 minute. Then:

```bash
terraform output
```

## Sanity check

```bash
ssh -i ~/.ssh/hetzner_k8s root@$(terraform output -raw control_plane_public_ip) hostname
# → prod-cp-1
```

(root works only until Ansible hardens SSH in the next step.)

## Notes

- **State file** (`terraform.tfstate`) is local and gitignored. It is the
  record of what exists — don't delete it. Remote state (S3/Terraform Cloud)
  is a later improvement.
- Changing a `server_type` in variables and re-applying will **rebuild** the
  server unless you rescale via console first. Check `terraform plan` output
  for "destroy" before saying yes to anything.

Next: [02 — Configure servers](02-configure-servers.md)
