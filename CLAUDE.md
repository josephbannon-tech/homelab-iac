# homelab-iac

OpenTofu for Proxmox VM provisioning on the single-node homelab (JBSRV01,
192.168.0.200). Public-intended portfolio repo (Phase 3 / Tier-1 candidate);
jbannon-only authorship, no Co-Authored-By trailers.

## What this is

Codifies the estate's hand-built VM convention into a reusable module:
clone a cloud-init golden template (Debian 13), configure via cloud-init.
Milestone 1 = VM provisioning only, proven on a disposable test VM.

## Hard rules

- **Plan before apply.** Always review `tofu plan` before `tofu apply`.
- **OpenTofu only manages its own state** — the template (VMID 9000) and test VM
  (110). The live production VMs (101-107) are NOT in state and must never be
  imported casually; that's a deliberate, later, one-at-a-time phase.
- **Disks on `local-lvm`**, never `local-lvm-m2` (faulty KIOXIA NVMe, a known
  open defect).
- **No secrets in git.** `terraform.tfvars` and `*.tfstate` are gitignored; only
  `terraform.tfvars.example` is committed. Use a scoped `terraform@pve` token,
  never `root@pam`.

## Conventions (mirror the estate)

`cpu=host`, `scsi_hardware=virtio-scsi-pci`, `bridge=vmbr0`, cloud-init drive,
`agent=enabled`, `machine=q35`, `ostype=l26`. VMIDs clear of the 101-107 prod range.

## Where things live

- Workshop knowledge base + per-host docs: `~/projects/homelab/`.
- Cluster GitOps (separate public repo): `~/projects/homelab-gitops/`.
