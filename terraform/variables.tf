variable "hcloud_token" {
  description = "Hetzner Cloud API token (read/write). Prefer env var: export TF_VAR_hcloud_token=... or HCLOUD_TOKEN=..."
  type        = string
  sensitive   = true
  default     = null # falls back to HCLOUD_TOKEN env var if unset
}

variable "cluster_name" {
  description = "Prefix for all resources; also used in Ansible/k8s naming"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Hetzner location. nbg1=Nuremberg, fsn1=Falkenstein, hel1=Helsinki"
  type        = string
  default     = "nbg1"
}

variable "image" {
  description = "OS image for all nodes. LTS on purpose — k8s package support lags new Ubuntu releases."
  type        = string
  default     = "ubuntu-24.04"
}

variable "control_plane_type" {
  description = "Server type for the control plane node"
  type        = string
  default     = "cx33" # 4 vCPU / 8 GB / 80 GB — kubeadm control plane needs >= 2 vCPU
}

variable "worker_type" {
  description = "Server type for the worker node"
  type        = string
  default     = "cx33"
}

variable "ssh_public_key_path" {
  description = "Public key installed as root's authorized key at server creation (Ansible bootstraps from this)"
  type        = string
  default     = "~/.ssh/hetzner_k8s.pub"
}

variable "network_cidr" {
  description = "Private network CIDR (node-to-node traffic: etcd, kubelet, Calico VXLAN)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet for the cluster nodes"
  type        = string
  default     = "10.0.1.0/24"
}

variable "control_plane_private_ip" {
  type    = string
  default = "10.0.1.10"
}

variable "worker_private_ip" {
  type    = string
  default = "10.0.1.20"
}

variable "allowed_ssh_cidrs" {
  description = "Who may reach SSH (22). Tighten to your home IP/32 for less noise; fail2ban covers the rest."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "allowed_api_cidrs" {
  description = "Who may reach the Kubernetes API (6443). Tighten to your home IP if it is stable."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}
