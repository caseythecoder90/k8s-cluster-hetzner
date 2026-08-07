output "control_plane_public_ip" {
  value = hcloud_server.control_plane.ipv4_address
}

output "worker_public_ip" {
  value = hcloud_server.worker.ipv4_address
}

output "control_plane_private_ip" {
  value = var.control_plane_private_ip
}

output "worker_private_ip" {
  value = var.worker_private_ip
}

output "ssh_control_plane" {
  description = "Convenience: ssh command for the control plane (after Ansible: user is 'deploy')"
  value       = "ssh -i ~/.ssh/hetzner_k8s deploy@${hcloud_server.control_plane.ipv4_address}"
}

# Render the Ansible inventory automatically so IPs never get copy-pasted by
# hand. Regenerated on every apply; gitignored (contains live IPs).
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory/hosts.yml"
  file_permission = "0644"
  content = templatefile("${path.module}/templates/hosts.yml.tpl", {
    cp_public_ip      = hcloud_server.control_plane.ipv4_address
    cp_private_ip     = var.control_plane_private_ip
    worker_public_ip  = hcloud_server.worker.ipv4_address
    worker_private_ip = var.worker_private_ip
    cluster_name      = var.cluster_name
  })
}
