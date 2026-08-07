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
