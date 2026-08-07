# Public-interface firewall applied to every node.
# Default is deny-all inbound; each rule below is an explicit allow.
# Outbound is unrestricted (no "out" rules defined = all allowed).

resource "hcloud_firewall" "cluster" {
  name = "${var.cluster_name}-fw"

  rule {
    description = "ICMP (ping, path MTU discovery)"
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "SSH"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.allowed_ssh_cidrs
  }

  rule {
    description = "Kubernetes API (kubectl from workstation)"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = var.allowed_api_cidrs
  }

  rule {
    description = "HTTP (ingress)"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "HTTPS (ingress)"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  # NodePort range (30000-32767) intentionally NOT exposed. The ingress
  # controller will bind 80/443 via hostNetwork or a hostPort instead.
  # Open specific ports here if you ever need a NodePort reachable publicly.
}
