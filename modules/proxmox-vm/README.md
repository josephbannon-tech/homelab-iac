# module: proxmox-vm

Provisions one Proxmox VM by cloning a cloud-init golden template and configuring
it via cloud-init (user + SSH keys, static-or-DHCP networking, DNS). Encapsulates
the estate's VM convention so callers only specify what differs.

Each VM also gets a rendered **vendor-data** snippet (uploaded per-VM to the
snippets datastore over SSH) carrying the estate baseline: qemu-guest-agent
installed + enabled on first boot, and, when `tailscale_auth_key` is set, a
tailnet join via `tailscale up --auth-key=...`. Vendor-data is *merged* by
cloud-init with the Proxmox-generated user-data, so the identity/network inputs
below keep working unchanged.

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
| `tailscale_auth_key` | `""` | reusable pre-authorized key; empty skips the tailnet join |
| `snippets_datastore_id` | `local` | must list `snippets` in its content types |
| `agent_enabled` | `true` | vendor-data installs the agent; set false for agent-less images |

## Outputs

`vm_id`, `name`, `ipv4_addresses` (from the qemu-guest-agent once booted).
