output "vm_id" {
  description = "Proxmox VMID"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "name" {
  value = proxmox_virtual_environment_vm.this.name
}

output "ipv4_addresses" {
  description = "IPv4 addresses reported by the qemu-guest-agent (once booted)"
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses
}
