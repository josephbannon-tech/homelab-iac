# homelab-iac

OpenTofu that provisions VMs on a single-node Proxmox VE host from a cloud-init
golden image. Codifies the convention the estate previously applied by hand
(virtio-scsi, host CPU, `local-lvm` disk with discard, qemu-guest-agent,
cloud-init drive, q35) into a reusable module, proven end-to-end on a disposable
VM.

## Layout

```
versions.tf            # OpenTofu + bpg/proxmox provider constraints
providers.tf           # Proxmox provider (token auth, SSH for image import)
variables.tf           # connection + shared inputs
main.tf                # golden Debian 13 template (download + import) + a test VM
outputs.tf
modules/proxmox-vm/    # reusable "clone the template + cloud-init" module
terraform.tfvars.example
```

## Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.6 (`tofu`).
- A Proxmox node reachable over the API, and a **scoped, least-privilege** API
  token (do **not** use `root@pam`). Create a dedicated role + user + token:

  ```sh
  pveum role add Terraform -privs "VM.Allocate VM.Audit VM.Clone \
    VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk \
    VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options \
    VM.Monitor VM.PowerMgmt Datastore.Allocate Datastore.AllocateSpace \
    Datastore.AllocateTemplate Datastore.Audit SDN.Use Sys.Audit"
  pveum user add terraform@pve
  pveum aclmod / -user terraform@pve -role Terraform
  pveum user token add terraform@pve tf --privsep 0
  ```

  The token grants only what VM provisioning needs — no `Sys.PowerMgmt`, no realm
  or user management, no root.

## Usage

```sh
cp terraform.tfvars.example terraform.tfvars   # fill in endpoint, token, SSH key
make init
make plan       # review: creates the template + the test VM, nothing else
make apply
# ... verify the test VM (ssh in, cloud-init status) ...
make destroy
```

State is local and gitignored, as is `terraform.tfvars`. Only
`terraform.tfvars.example` is committed.

## Scope

Milestone 1 is **VM provisioning only**. Tailscale auto-join and Pi-hole DNS
registration are planned phase 2; importing the existing production VMs into
state is a later, separate phase. OpenTofu only manages what is in its state —
the template and the test VM — and never touches the hand-built production VMs.
