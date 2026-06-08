output "template_vm_id" {
  description = "VMID of the Debian 13 golden template"
  value       = proxmox_virtual_environment_vm.debian13_template.vm_id
}

output "test_vm_id" {
  value = module.test_vm.vm_id
}

output "test_vm_ipv4" {
  description = "IPv4 of the test VM (from qemu-guest-agent once booted)"
  value       = module.test_vm.ipv4_addresses
}
