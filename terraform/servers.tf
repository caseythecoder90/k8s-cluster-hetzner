# SSH key injected as root's authorized key at creation time.
# Ansible's first run connects as root with this key, creates the 'deploy'
# user, then disables root SSH login entirely.
resource "hcloud_ssh_key" "admin" {
  name       = "${var.cluster_name}-admin"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "hcloud_server" "control_plane" {
  name         = "${var.cluster_name}-cp-1"
  server_type  = var.control_plane_type
  image        = var.image
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.admin.id]
  firewall_ids = [hcloud_firewall.cluster.id]

  labels = {
    cluster = var.cluster_name
    role    = "control-plane"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.cluster.id
    ip         = var.control_plane_private_ip
  }

  # Subnet must exist before a server can attach to the network
  depends_on = [hcloud_network_subnet.nodes]
}

resource "hcloud_server" "worker" {
  name         = "${var.cluster_name}-worker-1"
  server_type  = var.worker_type
  image        = var.image
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.admin.id]
  firewall_ids = [hcloud_firewall.cluster.id]

  labels = {
    cluster = var.cluster_name
    role    = "worker"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.cluster.id
    ip         = var.worker_private_ip
  }

  depends_on = [hcloud_network_subnet.nodes]
}
