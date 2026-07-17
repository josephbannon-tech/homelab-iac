terraform {
  required_version = ">= 1.6"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.66"
    }
    pihole = {
      source  = "poindexter12/pihole" # v6-API fork of ryanwholey/pihole; on the OpenTofu registry
      version = "~> 1.1"
    }
  }
}
