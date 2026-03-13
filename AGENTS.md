This file provides guidance to AI Agents when working with code in this repository.

## What This Project Is

Crucible Appliance builds a virtual machine (OVA) that runs cyber workforce development apps from CMU's Software Engineering Institute. It uses [Packer](https://www.packer.io/) to provision Ubuntu 24.04 with [K3s](https://k3s.io/) and deploys the full application stack via Helm on first boot.

Deployed apps (all under `https://crucible.local`): **TopoMojo** (virtual lab builder), **Gameboard** (competition manager), **Keycloak** (OIDC identity provider), **Gitea** (git server), **MkDocs** (documentation site).

Default credentials on the deployed appliance: `crucible` / `crucible`

## Build Commands

```bash
# Initialize Packer plugins (first time only)
packer init crucible-appliance.pkr.hcl

# Build appliance for a hypervisor (virtualbox or proxmox)
./build-appliance.sh virtualbox
./build-appliance.sh proxmox
./build-appliance.sh virtualbox,proxmox

# Build with Packer options (e.g., save partial builds, force overwrite)
./build-appliance.sh virtualbox -on-error=abort -force
```

The build version is derived automatically from git tags (release), branch+hash (dev), or `custom-YYYYMMDD` (no git).

For Proxmox builds, create `proxmox.auto.pkrvars.hcl` with `proxmox_url`, `proxmox_user`, `proxmox_password`, and `proxmox_node`.

If the hypervisor cannot reach Packer's HTTP server (e.g., dev container, CI runner, or remote Proxmox), use CD-ROM delivery instead:

```bash
./build-appliance.sh proxmox -var use_cidata=true
# Or add to proxmox.auto.pkrvars.hcl: use_cidata = true
```

## Helm Chart Development

The appliance uses a two-chart deployment model. Both charts are local; the crucible chart wraps the upstream `sei/crucible` chart as a subchart dependency alongside Gitea and MkDocs.

```bash
# Rebuild chart dependencies
helm dependency build crucible/charts/infra
helm dependency build crucible/charts/crucible

# On a deployed appliance, upgrade after editing values/templates
helm upgrade -n crucible infra /home/crucible/charts/infra
helm upgrade -n crucible crucible /home/crucible/charts/crucible --set global.version=$(cat /etc/appliance_version)
```

## Architecture

### Build Pipeline

1. **`crucible-appliance.pkr.hcl`** — Packer config defining VirtualBox and Proxmox sources; uses `http/user-data` for Ubuntu autoinstall and runs `setup-appliance.sh` via SSH provisioner.
2. **`http/user-data`** — Ubuntu cloud-config autoinstall: sets hostname/user to `crucible`, installs SSH server and qemu-guest-agent.
3. **`setup-appliance.sh`** — Runs during the Packer build phase; installs K3s prereqs (kubectl, helm, dnsmasq), builds Helm chart dependencies for both charts, configures MOTD and dnsmasq, installs two systemd one-shot services (`configure-nic` and `install-crucible`) that run on first boot.

### First Boot

- **`configure-nic`** → `crucible/scripts/configure-nic.sh` — Detects the primary NIC and writes a netplan config.
- **`install-crucible`** → `crucible/scripts/install-crucible.sh` — Installs K3s, creates the `crucible` namespace, installs cert-manager CRDs, then: (1) `helm install infra` (waits for CA + PostgreSQL), (2) `helm install crucible` (local chart with all apps).

### Helm Charts

**`crucible/charts/infra`** — Local infrastructure chart. Creates everything the crucible chart depends on:

- cert-manager with self-signed CA chain (`infra-selfsigned` → `infra-ca` → `infra-issuer` → `crucible-cert`)
- ingress-nginx (all apps path-routed under `crucible.local`)
- PostgreSQL (single shared instance)
- NFS server provisioner + PVCs for TopoMojo, Gameboard, Caster
- pgAdmin at `/pgadmin`
- Infrastructure secrets: PostgreSQL password, pgAdmin password, Gitea admin password (application-level secrets — OIDC clients, realm JSON, per-app API secrets — are created by the upstream sei/crucible chart when `createRealm` is enabled)
- Database creation Job (pre-install hook for all 14 application databases)

**`crucible/charts/crucible`** — Local chart wrapping three subchart dependencies:

- `sei-crucible` (alias for upstream [sei/crucible](https://github.com/cmu-sei/helm-charts/tree/main/charts/crucible)) — Keycloak + all Crucible apps, configured with `nameOverride: crucible` to keep `crucible-*` resource naming
- `gitea` (local Bitnami subchart) — Git server at `/gitea` with OIDC wired via post-install Job
- `mkdocs-material` (from sei repo) — Documentation site at `/start` with content seeded from Gitea

The chart also includes:

- A generated secret for the Gitea OIDC client (not included in the upstream realm)
- Post-install Jobs for Gitea OIDC configuration, MkDocs seeding, and Keycloak setup (crucible user + gitea-client registration)

### Key Template Patterns

**Secret persistence across reinstalls**: All secrets use `lookup` to read existing values and `helm.sh/resource-policy: keep`. The infra chart persists PostgreSQL, pgAdmin, and Gitea admin passwords. The upstream sei/crucible chart persists Keycloak auth, OIDC client secrets, and per-app API secrets. The local crucible chart persists the Gitea OIDC client secret.

**The `crucible-user-guid`** is a UUID generated on first install by the upstream sei/crucible chart and stored in `crucible-keycloak-auth`. It is passed as `Database__AdminId` to both TopoMojo and Gameboard APIs so both apps recognize the `crucible` Keycloak user as the database-level administrator.

**Global values** referenced across charts:

- `global.domain` (default: `crucible.local`) — used in ingress hosts, OIDC URIs, Keycloak realm JSON
- `global.version` — set from `/etc/appliance_version` at install time

### Dev Mode

`crucible/scripts/enable-dev-mode.sh` (runs without sudo on the deployed appliance) installs XFCE desktop, VS Code, Tailscale, and optionally exposes PostgreSQL externally. Run `./enable-dev-mode.sh --vim` to also install the Vim extension.

## Directory Reference

```
crucible-appliance.pkr.hcl   # Packer build definition
build-appliance.sh           # Build wrapper (version detection + packer build)
setup-appliance.sh           # OS configuration during Packer build
http/user-data               # Ubuntu autoinstall cloud-config
crucible/
  charts/
    infra/                   # Infrastructure + secrets
      templates/
        secret.yaml          # Infrastructure secrets (PostgreSQL, pgAdmin, Gitea admin)
        job.yaml             # Database creation job (pre-install hook)
        cert-manager.yaml    # CA chain and domain certificate
        pvc.yaml             # NFS PVCs for TopoMojo, Gameboard, Caster
    crucible/                # Application stack (wraps sei/crucible + Gitea + MkDocs)
      charts/gitea/          # Local Bitnami Gitea subchart
      files/mkdocs/          # MkDocs content seeded into Gitea on install
      templates/
        secret.yaml          # Gitea OIDC client secret (not in upstream realm)
        configmap.yaml       # Gitea env, MkDocs files, seed script
        job.yaml             # Gitea OIDC, MkDocs seed, Keycloak setup jobs
    README.md                # Chart architecture documentation
  scripts/
    install-crucible.sh       # First-boot K3s install + Helm deploy
    configure-nic.sh         # First-boot network config
    enable-dev-mode.sh       # Optional: XFCE + VS Code + Tailscale
    setup-proxmox.sh         # Helper for Proxmox SSL/DNS configuration
docs/
  proxmox.md                 # Proxmox integration setup guide
```
