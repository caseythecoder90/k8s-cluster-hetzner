# 00 — Prerequisites

One-time workstation setup. All infra commands run from **WSL Ubuntu**
(Terraform works on Windows too, but Ansible is Linux-only — simpler to do
everything in one place).

## 1. Install tooling in WSL

```bash
# Terraform (HashiCorp apt repo)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# Ansible (full package = includes the collections we use)
sudo apt install -y pipx && pipx ensurepath
pipx install --include-deps ansible

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
```

Verify: `terraform version && ansible --version && kubectl version --client`

## 2. Copy the SSH key into WSL

The `hetzner_k8s` keypair lives at `C:\Users\casey\.ssh\`. SSH refuses keys on
`/mnt/c/...` (permissions look world-readable), so copy into the WSL home:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp /mnt/c/Users/casey/.ssh/hetzner_k8s ~/.ssh/
cp /mnt/c/Users/casey/.ssh/hetzner_k8s.pub ~/.ssh/
chmod 600 ~/.ssh/hetzner_k8s && chmod 644 ~/.ssh/hetzner_k8s.pub
```

## 3. Hetzner API token

1. [Hetzner Cloud Console](https://console.hetzner.cloud/) → your project
2. **Security → API tokens → Generate API token**
3. Permissions: **Read & Write**. Copy it immediately (shown once).

Put it in your WSL shell profile so Terraform picks it up automatically:

```bash
echo 'export HCLOUD_TOKEN="paste-token-here"' >> ~/.bashrc && source ~/.bashrc
```

> The token grants full control of the project — treat it like a password.
> It lives only in `~/.bashrc` inside WSL, never in this repo.

## 4. Clone/access this repo from WSL

The repo is on the Windows filesystem; WSL sees it at:

```bash
cd /mnt/c/Users/casey/Projects/k8s-cluster-hetzner
```

(Cross-filesystem access is slower but fine for Terraform/Ansible workloads.)

## 5. Install Ansible collections

```bash
cd /mnt/c/Users/casey/Projects/k8s-cluster-hetzner/ansible
ansible-galaxy collection install -r requirements.yml
```

Next: [01 — Provision infrastructure](01-provision-infrastructure.md)
