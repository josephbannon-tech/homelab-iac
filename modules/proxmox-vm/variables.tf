variable "name" {
  description = "VM name / hostname"
  type        = string
}

variable "vm_id" {
  description = "Proxmox VMID"
  type        = number
}

variable "node_name" {
  description = "Proxmox node"
  type        = string
  default     = "JBSRV01"
}

variable "template_id" {
  description = "VMID of the cloud-init template to clone"
  type        = number
}

variable "description" {
  description = "VM description (shown in the Proxmox UI)"
  type        = string
  default     = "Managed by OpenTofu (homelab-iac)"
}

variable "tags" {
  description = "Proxmox tags"
  type        = list(string)
  default     = ["opentofu"]
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  description = "Dedicated memory in MB"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Root disk size in GB (>= the template's disk)"
  type        = number
  default     = 20
}

variable "datastore_id" {
  description = "Datastore for the VM disk + cloud-init drive"
  type        = string
  default     = "local-lvm"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "ip_address" {
  description = "IPv4 as CIDR (e.g. 192.168.0.110/24) or the literal \"dhcp\""
  type        = string
  default     = "dhcp"
}

variable "ip_gateway" {
  description = "IPv4 gateway (ignored when ip_address is dhcp)"
  type        = string
  default     = "192.168.0.1"
}

variable "dns_servers" {
  type    = list(string)
  default = ["192.168.0.205"]
}

variable "username" {
  description = "cloud-init user"
  type        = string
  default     = "claude"
}

variable "ssh_public_keys" {
  type = list(string)
}

variable "on_boot" {
  description = "Start the VM on host boot"
  type        = bool
  default     = false
}

variable "agent_enabled" {
  description = "Enable QEMU guest-agent integration (lets the provider read VM IPs back). The vendor-data baseline installs the agent on first boot, so this defaults true; set false only if you point the VM at an image/vendor-data without the agent — otherwise bpg waits up to its agent timeout on every plan/refresh."
  type        = bool
  default     = true
}

variable "tailscale_auth_key" {
  description = "Reusable pre-authorized Tailscale auth key; the VM joins the tailnet on first boot. Empty string skips the join."
  type        = string
  default     = ""
  sensitive   = true
}

variable "snippets_datastore_id" {
  description = "Datastore for the vendor-data snippet (must list 'snippets' in its content types)"
  type        = string
  default     = "local"
}
