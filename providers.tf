provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  # bpg/proxmox needs an SSH connection to the node for the disk-import step
  # (cloning + cloud-init are pure API). Uses root SSH (the well-trodden bpg path;
  # avoids non-root sudo handling for qm/pvesm) with the passphraseless key.
  ssh {
    agent       = false
    username    = var.proxmox_ssh_username
    private_key = file(pathexpand(var.proxmox_ssh_private_key_path))
  }
}
