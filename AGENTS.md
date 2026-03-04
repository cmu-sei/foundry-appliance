This file provides guidance to AI Agents when working with code in this repository.

## What This Project Is

Foundry Appliance builds a virtual machine (OVA) that runs cyber workforce development apps from CMU's Software Engineering Institute. It uses [Packer](https://www.packer.io/) to provision Ubuntu 24.04 with [K3s](https://k3s.io/) and deploys the full application stack via Helm on first boot.

Deployed apps (all under `https://foundry.local`): **TopoMojo** (virtual lab builder), **Gameboard** (competition manager), **Keycloak** (OIDC identity provider), **Gitea** (git server), **MkDocs** (documentation site).

Default credentials on the deployed appliance: `foundry` / `foundry`

## Build Commands

```bash
# Initialize Packer plugins (first time only)
packer init foundry-appliance.pkr.hcl

# Build appliance for a hypervisor (virtualbox or proxmox)
./build-appliance.sh virtualbox
./build-appliance.sh proxmox
./build-appliance.sh virtualbox,proxmox

# Build with Packer options (e.g., save partial builds, force overwrite)
./build-appliance.sh virtualbox -on-error=abort -force
```

The build version is derived automatically from git tags (release), branch+hash (dev), or `custom-YYYYMMDD` (no git).

For Proxmox builds, create `proxmox.auto.pkrvars.hcl` with `proxmox_url`, `proxmox_user`, `proxmox_password`, and `proxmox_node`.

## Helm Chart Development

The Helm charts live at `foundry/charts/` and are copied to the appliance at `/home/foundry/charts/` during the Packer build.

```bash
# Rebuild chart dependencies (run from the appliance or with helm installed locally)
helm dependency build foundry/charts/infra
helm dependency build foundry/charts/foundry

# On a deployed appliance, upgrade after editing values/templates
helm upgrade -n foundry infra /home/foundry/charts/infra
helm upgrade -n foundry foundry /home/foundry/charts/foundry --set global.version=$(cat /etc/appliance_version)
```

## Architecture

### Build Pipeline

1. **`foundry-appliance.pkr.hcl`** — Packer config defining VirtualBox and Proxmox sources; uses `http/user-data` for Ubuntu autoinstall and runs `setup-appliance.sh` via SSH provisioner.
2. **`http/user-data`** — Ubuntu cloud-config autoinstall: sets hostname/user to `foundry`, installs SSH server and qemu-guest-agent.
3. **`setup-appliance.sh`** — Runs during the Packer build phase; installs K3s prereqs (kubectl, helm, dnsmasq), builds Helm chart dependencies, configures MOTD and dnsmasq, installs two systemd one-shot services (`configure-nic` and `install-foundry`) that run on first boot.

### First Boot

- **`configure-nic`** → `foundry/scripts/configure-nic.sh` — Detects the primary NIC and writes a netplan config.
- **`install-foundry`** → `foundry/scripts/install-foundry.sh` — Installs K3s, creates the `foundry` namespace, installs cert-manager CRDs, then deploys `helm install infra` (waits for CA secret) then `helm install foundry`.

### Helm Charts

**`foundry/charts/infra`** — Infrastructure only: cert-manager + a self-signed ClusterIssuer (`infra-selfsigned`) that bootstraps a 10-year CA (`infra-ca`), which is then used by the `infra-issuer` ClusterIssuer to sign all application TLS certs.

**`foundry/charts/foundry`** — Full application stack as a single Helm chart with sub-chart dependencies:

- `nfs-server-provisioner` — Shared NFS storage for TopoMojo file uploads
- `ingress-nginx` — Reverse proxy; all apps path-routed under `foundry.local`
- `postgresql` (Bitnami legacy) — Single shared database; creates `keycloak` and `gitea` databases at init
- `keycloak` (Bitnami legacy) — OIDC provider; realm `foundry` configured via `keycloak-config-cli` with clients for TopoMojo, Gameboard, Gitea, and their Swagger UIs
- `gitea` — Git server at `/gitea`; OIDC registration via Keycloak wired via a post-install Helm Job
- `mkdocs-material` — Documentation at `/start`; content seeded from `foundry/charts/foundry/files/mkdocs/` via a Helm Job that pushes to Gitea
- `topomojo` — Virtual lab builder at `/topomojo`
- `gameboard` — Competition manager at `/gameboard`

### Key Template Patterns

**Secret persistence across reinstalls** (`templates/secret.yaml`): All secrets use `lookup` to read existing values and `helm.sh/resource-policy: keep`. This means PostgreSQL password, Gitea admin password, Keycloak admin password, OAuth client secret, and the foundry user GUID all persist when running `helm upgrade`.

**The `foundry-user-guid`** is a UUID generated on first install and stored in the Keycloak auth secret. It is passed as `Database__AdminId` to both TopoMojo and Gameboard APIs so both apps recognize the `foundry` Keycloak user as the database-level administrator.

**Global values** referenced across sub-charts:

- `global.domain` (default: `foundry.local`) — used in ingress hosts, OIDC URIs, Keycloak realm JSON
- `global.infraHelmRelease` (default: `infra`) — used to reference the `infra-ca` and `infra-issuer` resources from the infra chart
- `global.version` — set from `/etc/appliance_version` at install time

### Dev Mode

`foundry/scripts/enable-dev-mode.sh` (runs without sudo on the deployed appliance) installs XFCE desktop, VS Code, Tailscale, and optionally exposes PostgreSQL externally. Run `./enable-dev-mode.sh --vim` to also install the Vim extension.

## Directory Reference

```
foundry-appliance.pkr.hcl   # Packer build definition
build-appliance.sh           # Build wrapper (version detection + packer build)
setup-appliance.sh           # OS configuration during Packer build
http/user-data               # Ubuntu autoinstall cloud-config
foundry/
  charts/
    infra/                   # cert-manager + CA infrastructure
    foundry/                 # Full application stack
      files/mkdocs/          # MkDocs content seeded into Gitea on install
      templates/
        secret.yaml          # All secrets with idempotent lookup logic
        configmap.yaml       # Gitea env, Keycloak realm JSON, MkDocs files
        job.yaml             # Post-install jobs: OIDC wiring, mkdocs seed, foundry user
        pvc.yaml             # NFS PVC for TopoMojo
  scripts/
    install-foundry.sh       # First-boot K3s install + Helm deploy
    configure-nic.sh         # First-boot network config
    enable-dev-mode.sh       # Optional: XFCE + VS Code + Tailscale
    setup-proxmox.sh         # Helper for Proxmox SSL/DNS configuration
docs/
  proxmox.md                 # Proxmox integration setup guide
```
