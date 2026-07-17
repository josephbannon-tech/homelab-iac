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
# Phase 2 shape: static IP + vendor-data baseline (guest agent + tailnet join)
# + Pi-hole DNS registration.

locals {
  test_vm_name = "tf-test-02"
  test_vm_ip   = "192.168.0.210"
}

module "test_vm" {
  source = "./modules/proxmox-vm"

  name        = local.test_vm_name
  vm_id       = 110
  node_name   = var.proxmox_node
  template_id = proxmox_virtual_environment_vm.debian13_template.vm_id
  description = "OpenTofu lifecycle test VM (disposable)"
  tags        = ["opentofu", "test"]

  cores     = 2
  memory    = 2048
  disk_size = 20

  ip_address      = "${local.test_vm_ip}/24"
  ip_gateway      = "192.168.0.1"
  dns_servers     = var.dns_servers
  username        = var.vm_username
  ssh_public_keys = var.ssh_public_keys

  tailscale_auth_key = var.tailscale_auth_key
}

# Statically-addressed VMs get a Pi-hole A record; DHCP VMs already receive a
# DHCP-derived *.lan name, so only static ones need explicit registration.
resource "pihole_dns_record" "test_vm" {
  domain = "${local.test_vm_name}.lan"
  ip     = local.test_vm_ip
}
