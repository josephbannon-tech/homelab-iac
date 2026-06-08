# module: proxmox-vm

Provisions one Proxmox VM by cloning a cloud-init golden template and configuring
it via cloud-init (user + SSH keys, static-or-DHCP networking, DNS). Encapsulates
the estate's VM convention so callers only specify what differs.

## Usage

```hcl
module "example" {
  source = "./modules/proxmox-vm"

  name        = "example-01"
  vm_id       = 120
  template_id = 9000              # the golden template VMID

  cores     = 2
  memory    = 4096
  disk_size = 40

  ip_address      = "192.168.0.120/24"   # or "dhcp"
  ip_gateway      = "192.168.0.1"
  username        = "claude"
  ssh_public_keys = var.ssh_public_keys
}
```

## Key inputs

| Variable | Default | Notes |
|----------|---------|-------|
| `name`, `vm_id` | — | required; VMID must be free and clear of prod |
| `template_id` | — | VMID of the cloud-init template to clone |
| `cores`, `memory`, `disk_size` | 2 / 2048 MB / 20 GB | |
| `datastore_id` | `local-lvm` | **not** `local-lvm-m2` (faulty NVMe) |
| `ip_address` | `dhcp` | CIDR for static, or `"dhcp"` |
| `ssh_public_keys` | — | injected via cloud-init |

## Outputs

`vm_id`, `name`, `ipv4_addresses` (from the qemu-guest-agent once booted).
