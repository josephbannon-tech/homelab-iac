# A single Proxmox VM cloned from a cloud-init golden template, configured via
# cloud-init. Mirrors the estate's hand-built convention (virtio-scsi, host CPU,
# local-lvm disk with discard, qemu-guest-agent, cloud-init drive, q35).

# Estate-baseline vendor-data (qemu-guest-agent + optional tailnet join),
# uploaded as a per-VM snippet. Snippet upload is an SSH operation (not API),
# and the rendered file is root-readable on the node — the Tailscale auth key
# transits both. The snippets datastore must list `snippets` in its content types.
resource "proxmox_virtual_environment_file" "vendor_data" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore_id
  node_name    = var.node_name

  source_raw {
    file_name = "${var.name}-vendor-data.yaml"
    data = templatefile("${path.module}/templates/vendor-data.yaml.tftpl", {
      tailscale_auth_key = var.tailscale_auth_key
    })
  }
}

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
    enabled = var.agent_enabled
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

    vendor_data_file_id = proxmox_virtual_environment_file.vendor_data.id

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
