# homelab-iac

OpenTofu that provisions VMs on a single-node Proxmox VE host from a cloud-init
golden image. Codifies the convention the estate previously applied by hand
(virtio-scsi, host CPU, `local-lvm` disk with discard, qemu-guest-agent,
cloud-init drive, q35) into a reusable module, proven end-to-end on a disposable
VM.

A provisioned VM comes up as a finished network citizen, not just a booted OS:
cloud-init **vendor-data** installs the QEMU guest agent (so Terraform reads the
VM's real IP back and outputs are populated), joins the machine to the tailnet
with a pre-authorized auth key, and the plan registers a Pi-hole local-DNS
record for statically-addressed VMs. `tofu destroy` unwinds the DNS record with
the VM.

## Layout

```
versions.tf            # OpenTofu + provider constraints (bpg/proxmox, pihole)
providers.tf           # Proxmox (token auth, SSH for image import) + Pi-hole
variables.tf           # connection + shared inputs
main.tf                # golden Debian 13 template + a test VM + its DNS record
outputs.tf
modules/proxmox-vm/    # reusable "clone + cloud-init + vendor-data" module
terraform.tfvars.example
```

## Why vendor-data (the cloud-init layering)

Proxmox generates the cloud-init **user-data** itself (user account, SSH keys,
hostname, network from the `initialization {}` block). Overriding user-data via
`cicustom` replaces all of that, so this repo doesn't. Instead the module
renders a per-VM **vendor-data** snippet, which cloud-init *merges* alongside
the Proxmox-generated user-data: per-machine identity stays provider-managed,
and vendor-data carries only the estate baseline (guest agent, tailnet join).
Snippet upload is an SSH operation (the Proxmox API has no snippets endpoint),
and the target datastore must list `snippets` in its content types:

```sh
pvesm set local --content backup,vztmpl,snippets,iso,import
```

## Prerequisites

- [OpenTofu](https://opentofu.org/) >= 1.6 (`tofu`).
- A Proxmox node reachable over the API, and a **scoped, least-privilege** API
  token (do **not** use `root@pam`). Create a dedicated role + user + token:

  ```sh
  pveum role add Terraform -privs "VM.Allocate VM.Audit VM.Clone \
    VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk \
    VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options \
    VM.GuestAgent.Audit VM.PowerMgmt Datastore.Allocate Datastore.AllocateSpace \
    Datastore.AllocateTemplate Datastore.Audit SDN.Use Sys.Audit"
  pveum user add terraform@pve
  pveum aclmod / -user terraform@pve -role Terraform
  pveum user token add terraform@pve tf --privsep 0
  ```

  The token grants only what VM provisioning needs — no `Sys.Modify`/`Sys.PowerMgmt`,
  no realm or user management, no root. (`VM.GuestAgent.Audit` lets the provider read
  a VM's IP back from the guest agent; without it the apply still succeeds but
  `*_ipv4` outputs come back empty.)

  Two operations sit outside the API token: bpg imports the cloud image over **root
  SSH** to the node (configure the provider `ssh {}` block), and the Debian image
  itself is staged once to `local:import/` outside Terraform (the URL-download API
  needs `Sys.Modify`, deliberately omitted).

## Usage

```sh
cp terraform.tfvars.example terraform.tfvars   # fill in endpoint, token, SSH key
make init
make plan       # review: creates the template + the test VM, nothing else
make apply
# ... verify the test VM (ssh in, cloud-init status) ...
make destroy
```

State is local and gitignored, as is `terraform.tfvars` (non-secret values
only since 2026-10-01). Only `terraform.tfvars.example` is committed.

## Secrets: SOPS + age (2026-10-01)

The three sensitive variables (`proxmox_api_token`, `tailscale_auth_key`,
`pihole_password`) are committed **encrypted** in `secrets.sops.tfvars.json`,
one value per key, ciphertext from [SOPS](https://github.com/getsops/sops) with
an [age](https://age-encryption.org/) recipient (`.sops.yaml`). The Makefile
targets wrap every plan and apply in `sops exec-file`, which decrypts to a
private temp file for the lifetime of one command:

```bash
make plan            # sops exec-file secrets.sops.tfvars.json 'tofu plan -var-file={}'
make secrets-edit    # opens the decrypted JSON in $EDITOR, re-encrypts on save
make secrets-check   # fails if any value is not an ENC[...] ciphertext (also CI)
```

Why file-level SOPS here and Sealed Secrets in the cluster repo: Sealed Secrets
is the right shape where a controller decrypts at apply time inside the
cluster; an OpenTofu run has no controller, it needs the values on the
operator's machine for the duration of a plan. SOPS encrypts values and leaves
keys readable, so a diff shows *which* secret changed without showing it.

Key custody: the age private key lives on the operations host at
`~/.config/sops/age/keys.txt` (0600), is included in that host's nightly
secrets backup, and reaches off-site storage through the same seed. A second
operator means a second recipient in `.sops.yaml` and `sops updatekeys`.

Trade-off: `tofu plan` by hand no longer works without the var-file; the
Makefile is the interface. That is the point: there is one way to run it, and
it never leaves plaintext behind.

## Estate integration (phase 2)

- **Tailscale**: vendor-data installs Tailscale and runs
  `tailscale up --auth-key=...` on first boot with a **reusable, pre-authorized**
  auth key (`tailscale_auth_key`, gitignored tfvars; no tags on a personal
  tailnet). Empty string skips the join. Note the rendered snippet is
  root-readable on the Proxmox node — acceptable here, since node root already
  owns every VM disk.
- **Pi-hole DNS**: statically-addressed VMs get a `<name>.lan` A record via the
  [`poindexter12/pihole`](https://search.opentofu.org/provider/poindexter12/pihole/latest)
  provider (the Pi-hole v6 REST API fork available on the OpenTofu registry).
  DHCP VMs already receive DHCP-derived names, so only static ones are
  registered.
- **Trade-off**: first boot now blocks on `apt update` + two package installs
  (~2-3 min instead of ~40 s) before the agent answers and the apply returns.
  Provisioning is rare; a VM that is *done* when the apply returns is worth it.

## Scope

Importing the existing production VMs into state is a later, separate phase.
OpenTofu only manages what is in its state — the template and the test VM — and
never touches the hand-built production VMs.
