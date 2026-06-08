provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  # bpg/proxmox needs an SSH connection to the node for a few operations that the
  # API can't do alone (notably importing a downloaded cloud image into a disk).
  # Uses the local SSH agent for the configured user (claude has sudo on JBSRV01).
  ssh {
    agent    = true
    username = var.proxmox_ssh_username
  }
}
