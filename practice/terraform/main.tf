# Disposable CKAD lab: same architecture as ../../terraform, consolidated
# into one file, with lab-sized defaults. Own state = own lifecycle;
# `terraform destroy` here can never touch prod resources.

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.51"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "hcloud" {} # HCLOUD_TOKEN env var

# A second lab next to the first: `terraform workspace new <name>` gives that
# workspace its own state, and everything below derives from the workspace so
# nothing collides with the default lab. Workspace "hk" => cluster "lab-hk",
# servers lab-hk-cp-1 / lab-hk-worker-1, inventory hosts-hk.yml.
# The default workspace keeps the original names, so existing state is untouched.
locals {
  cluster_name = terraform.workspace == "default" ? var.cluster_name : "${var.cluster_name}-${terraform.workspace}"
  inventory    = terraform.workspace == "default" ? "hosts.yml" : "hosts-${terraform.workspace}.yml"
}

variable "cluster_name" {
  type    = string
  default = "lab"
}

variable "location" {
  type    = string
  default = "nbg1"
}

variable "image" {
  type    = string
  default = "ubuntu-24.04"
}

variable "node_type" {
  description = "Both lab nodes. cx23 (2 vCPU/4GB) is enough for CKAD workloads."
  type        = string
  default     = "cx23"
}

variable "worker_type" {
  description = "Worker-only override for when node_type is out of stock. Null = use node_type. Changing this must NOT rebuild the control plane."
  type        = string
  default     = null
}

variable "worker_location" {
  description = "Worker-only location override. Must stay inside the eu-central network zone (nbg1/fsn1/hel1) or the private network can't reach it."
  type        = string
  default     = null
}

variable "ipv6_enabled" {
  description = "Public IPv6 on both nodes. Each enabled address family costs a Hetzner Primary IP and the project has a Primary IP limit, so a second lab next to the first only fits IPv4-only (-var ipv6_enabled=false). Nothing in the lab uses IPv6."
  type        = bool
  default     = true
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/hetzner_k8s.pub"
}

resource "hcloud_network" "lab" {
  name     = "${local.cluster_name}-net"
  ip_range = "10.10.0.0/16"
}

resource "hcloud_network_subnet" "nodes" {
  network_id   = hcloud_network.lab.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.10.1.0/24"
}

resource "hcloud_firewall" "lab" {
  name = "${local.cluster_name}-fw"

  rule {
    description = "ICMP"
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
  rule {
    description = "SSH"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
  rule {
    description = "Kubernetes API"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
  rule {
    # CKAD tasks frequently expose NodePort services and curl them —
    # open the whole range; it's a short-lived lab.
    description = "NodePort range"
    direction   = "in"
    protocol    = "tcp"
    port        = "30000-32767"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}

# The same public key can only be uploaded once per Hetzner project, and
# prod's Terraform already owns it under the name "prod-admin". A data source
# references that existing upload instead of creating a duplicate.
# (Consequence: prod's key must exist for lab applies — fine, prod outlives lab.)
data "hcloud_ssh_key" "admin" {
  name = "prod-admin"
}

resource "hcloud_server" "control_plane" {
  name         = "${local.cluster_name}-cp-1"
  server_type  = var.node_type
  image        = var.image
  location     = var.location
  ssh_keys     = [data.hcloud_ssh_key.admin.id]
  firewall_ids = [hcloud_firewall.lab.id]
  labels       = { cluster = local.cluster_name, role = "control-plane" }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = var.ipv6_enabled
  }
  network {
    network_id = hcloud_network.lab.id
    ip         = "10.10.1.10"
  }
  depends_on = [hcloud_network_subnet.nodes]
}

resource "hcloud_server" "worker" {
  name = "${local.cluster_name}-worker-1"
  # coalesce = "first non-null": the overrides let you dodge a stock outage
  # on the worker without rebuilding the control plane.
  server_type  = coalesce(var.worker_type, var.node_type)
  image        = var.image
  location     = coalesce(var.worker_location, var.location)
  ssh_keys     = [data.hcloud_ssh_key.admin.id]
  firewall_ids = [hcloud_firewall.lab.id]
  labels       = { cluster = local.cluster_name, role = "worker" }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = var.ipv6_enabled
  }
  network {
    network_id = hcloud_network.lab.id
    ip         = "10.10.1.20"
  }
  depends_on = [hcloud_network_subnet.nodes]
}

# Reuses the prod inventory template — same Ansible roles, different targets
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory/${local.inventory}"
  file_permission = "0644"
  content = templatefile("${path.module}/../../terraform/templates/hosts.yml.tpl", {
    cluster_name      = local.cluster_name
    cp_public_ip      = hcloud_server.control_plane.ipv4_address
    cp_private_ip     = "10.10.1.10"
    worker_public_ip  = hcloud_server.worker.ipv4_address
    worker_private_ip = "10.10.1.20"
  })
}

output "control_plane_public_ip" {
  value = hcloud_server.control_plane.ipv4_address
}

output "worker_public_ip" {
  value = hcloud_server.worker.ipv4_address
}

output "ssh_control_plane" {
  value = "ssh -i ~/.ssh/hetzner_k8s deploy@${hcloud_server.control_plane.ipv4_address}"
}
