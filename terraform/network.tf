# Private network for node-to-node traffic. The Hetzner Cloud firewall only
# applies to PUBLIC interfaces, so everything on this network (etcd :2379,
# kubelet :10250, Calico VXLAN :4789/udp, apiserver :6443) flows freely
# between nodes without us opening those ports to the internet.

resource "hcloud_network" "cluster" {
  name     = "${var.cluster_name}-net"
  ip_range = var.network_cidr
}

resource "hcloud_network_subnet" "nodes" {
  network_id   = hcloud_network.cluster.id
  type         = "cloud"
  network_zone = "eu-central" # covers nbg1, fsn1, hel1
  ip_range     = var.subnet_cidr
}
