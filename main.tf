# ---- Golden image: Debian 13 cloud-init template, as code ---------------------

# The Debian 13 generic cloud image is staged once on the node's `local` import
# storage (outside Terraform, to keep the API token minimal — the URL download
# endpoint needs Sys.Modify, which the scoped terraform@pve token deliberately
# lacks). Re-stage with:
#   curl -fsSL -o /var/lib/vz/import/debian-13-genericcloud-amd64.qcow2 \
#     "$debian13_image_url"   # see var.debian13_image_url
# The template below imports it; bpg does the disk import over SSH/sudo.

# A stopped template VM that imports that image. Clones inherit the disk + agent
# + cloud-init drive; each clone injects its own user/keys/network via cloud-init.
resource "proxmox_virtual_environment_vm" "debian13_template" {
  name      = "debian13-cloudinit"
  node_name = var.proxmox_node
  vm_id     = var.template_vm_id
  template  = true
  started   = false
  tags      = ["opentofu", "template"]

  machine       = "q35"
  bios          = "seabios"
  scsi_hardware = "virtio-scsi-pci"

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = var.template_image_file_id
    interface    = "scsi0"
    discard      = "on"
    size         = 20
  }

  initialization {
    datastore_id = "local-lvm"
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}
}

# ---- Test VM: proves the module end-to-end (create -> verify -> destroy) -------

module "test_vm" {
  source = "./modules/proxmox-vm"

  name        = "tf-test-01"
  vm_id       = 110
  node_name   = var.proxmox_node
  template_id = proxmox_virtual_environment_vm.debian13_template.vm_id
  description = "OpenTofu lifecycle test VM (disposable)"
  tags        = ["opentofu", "test"]

  cores     = 2
  memory    = 2048
  disk_size = 20

  ip_address      = "dhcp"
  dns_servers     = var.dns_servers
  username        = var.vm_username
  ssh_public_keys = var.ssh_public_keys
}
