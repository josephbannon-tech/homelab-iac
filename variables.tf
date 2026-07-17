# ---- Proxmox connection -------------------------------------------------------

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, e.g. https://192.168.0.200:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token in the form USER@REALM!TOKENID=SECRET (scoped terraform@pve!tf)"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification (the node uses a self-signed cert)"
  type        = bool
  default     = true
}

variable "proxmox_ssh_username" {
  description = "SSH user on the Proxmox node for bpg operations that need it (root: clean disk-import path)"
  type        = string
  default     = "root"
}

variable "proxmox_ssh_private_key_path" {
  description = "Path to the passphraseless SSH private key bpg uses to reach the node"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "JBSRV01"
}

# ---- Golden template ----------------------------------------------------------

variable "debian13_image_url" {
  description = "Source URL for the Debian 13 cloud image (staged on the node outside TF; see main.tf)"
  type        = string
  default     = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
}

variable "template_image_file_id" {
  description = "Proxmox volume ID of the pre-staged cloud image to import into the template"
  type        = string
  default     = "local:import/debian-13-genericcloud-amd64.qcow2"
}

variable "template_vm_id" {
  description = "VMID for the golden cloud-init template (well clear of prod 101-107)"
  type        = number
  default     = 9000
}

# ---- Estate integration: Tailscale + Pi-hole -----------------------------------

variable "tailscale_auth_key" {
  description = "Reusable pre-authorized Tailscale auth key injected into VMs via vendor-data (mint at https://login.tailscale.com/admin/settings/keys — no tags on a personal tailnet). Empty string skips the tailnet join."
  type        = string
  default     = ""
  sensitive   = true
}

variable "pihole_url" {
  description = "Pi-hole (JBDNS01) base URL for local-DNS registration"
  type        = string
  default     = "http://192.168.0.205"
}

variable "pihole_password" {
  description = "Pi-hole web/API password used to manage local DNS records"
  type        = string
  sensitive   = true
}

# ---- Shared VM inputs ---------------------------------------------------------

variable "ssh_public_keys" {
  description = "SSH public keys injected into provisioned VMs via cloud-init"
  type        = list(string)
}

variable "vm_username" {
  description = "Default cloud-init user created on provisioned VMs"
  type        = string
  default     = "claude"
}

variable "dns_servers" {
  description = "DNS servers pushed via cloud-init (Pi-hole)"
  type        = list(string)
  default     = ["192.168.0.205"]
}
