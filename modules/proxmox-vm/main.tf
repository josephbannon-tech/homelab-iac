# A single Proxmox VM cloned from a cloud-init golden template, configured via
# cloud-init. Mirrors the estate's hand-built convention (virtio-scsi, host CPU,
# local-lvm disk with discard, qemu-guest-agent, cloud-init drive, q35).

resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  description = var.description
  node_name   = var.node_name
  vm_id       = var.vm_id
  tags        = var.tags

  started = true
  on_boot = var.on_boot

  machine       = "q35"
  bios          = "seabios"
  scsi_hardware = "virtio-scsi-pci"

  clone {
    vm_id = var.template_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    discard      = "on"
    size         = var.disk_size
  }

  network_device {
    bridge = var.bridge
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  initialization {
    datastore_id = var.datastore_id

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.ip_address == "dhcp" ? null : var.ip_gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      username = var.username
      keys     = var.ssh_public_keys
    }
  }

  lifecycle {
    # The cloud image disk size is fixed by the template; ignore drift on fields
    # the provider may re-read differently after a clone.
    ignore_changes = [
      clone,
    ]
  }
}
