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

The appliance uses a three-chart deployment model. All charts are local wrappers around the upstream `sei/crucible-operators`, `sei/crucible-infra`, and `sei/crucible-apps` charts.

```bash
# Rebuild chart dependencies
helm dependency build crucible/charts/operators
helm dependency build crucible/charts/infra
helm dependency build crucible/charts/crucible

# On a deployed appliance, upgrade after editing values/templates
helm upgrade -n crucible crucible-operators /home/crucible/charts/operators
helm upgrade -n crucible crucible-infra /home/crucible/charts/infra
helm upgrade -n crucible crucible /home/crucible/charts/crucible --set global.version=$(cat /etc/appliance_version)
```

## Architecture

### Build Pipeline

1. **`crucible-appliance.pkr.hcl`** — Packer config defining VirtualBox and Proxmox sources; uses `http/user-data` for Ubuntu autoinstall and runs `setup-appliance.sh` via SSH provisioner.
2. **`http/user-data`** — Ubuntu cloud-config autoinstall: sets hostname/user to `crucible`, installs SSH server and qemu-guest-agent.
3. **`setup-appliance.sh`** — Runs during the Packer build phase; installs K3s prereqs (kubectl, helm, dnsmasq), builds Helm chart dependencies for all three charts, configures MOTD and dnsmasq, installs two systemd one-shot services (`configure-nic` and `install-crucible`) that run on first boot.

### First Boot

- **`configure-nic`** → `crucible/scripts/configure-nic.sh` — Detects the primary NIC and writes a netplan config.
- **`install-crucible`** → `crucible/scripts/install-crucible.sh` — Installs K3s, creates the `crucible` namespace, installs cert-manager CRDs, then: (1) `helm install crucible-operators` (Keycloak Operator + CloudNative-PG), (2) `helm install crucible-infra` (waits for CA + CNPG Cluster), (3) `helm install crucible` (all applications).

### Helm Charts

**`crucible/charts/operators`** — Thin wrapper around the upstream [sei/crucible-operators](https://github.com/cmu-sei/helm-charts/tree/main/charts/crucible-operators) chart. Installs cluster-scoped prerequisites: the Keycloak Operator (`Keycloak` + `KeycloakRealmImport` CRDs) and CloudNative-PG (`Cluster` CRD).

**`crucible/charts/infra`** — Wraps the upstream [sei/crucible-infra](https://github.com/cmu-sei/helm-charts/tree/main/charts/crucible-infra) chart. It provides:

- CNPG PostgreSQL `Cluster` with auto-provisioned per-app databases and users (each app gets its own user via CNPG-managed secrets `crucible-infra-db-{name}`)
- ingress-nginx (all apps path-routed under `crucible.local`)
- NFS server provisioner + PVCs for TopoMojo, Gameboard, Caster
- pgAdmin at `/pgadmin`

Local additions on top of the upstream chart:

- cert-manager with a self-signed CA chain (`crucible-infra-selfsigned` → `crucible-infra-ca` → `crucible-infra-issuer` → `crucible-cert`) — keeps the appliance working offline
- Gitea admin password Secret (`crucible-infra-gitea-admin`)

**`crucible/charts/crucible`** — Wraps three subcharts:

- `crucible-apps` (upstream [sei/crucible-apps](https://github.com/cmu-sei/helm-charts/tree/main/charts/crucible-apps)) — Keycloak (deployed via the Keycloak Operator) + all Crucible apps + Moodle. Configured with `fullnameOverride: crucible` so resource names stay `crucible-*`. `createRealm: true` generates the crucible realm, OIDC client secrets, and the default `crucible` realm admin user on first install.
- `gitea` (local Bitnami subchart) — Git server at `/gitea` with OIDC wired via post-install Job
- `mkdocs-material` (from sei repo) — Documentation site at `/start` with content seeded from Gitea

The chart also includes:

- A generated secret for the Gitea OIDC client (not included in the upstream realm)
- Post-install Jobs: Gitea OIDC auth source config, MkDocs seeding, and gitea-client registration in the Keycloak crucible realm

### Key Template Patterns

**Secret persistence across reinstalls**: All generated secrets use `lookup` + `helm.sh/resource-policy: keep`. The upstream `crucible-infra` chart persists PostgreSQL superuser + per-database user passwords and the pgAdmin password. The upstream `crucible-apps` chart persists Keycloak admin auth and OIDC client secrets (including the realm admin password) in `crucible-oidc-client-secrets`. The local infra chart persists the Gitea admin password; the local crucible chart persists the Gitea OIDC client secret.

**Admin via realm role**: Gameboard and TopoMojo identify the `crucible` user as admin via the `Administrator` realm role claim (`Oidc__UserRolesClaimMap__administrator: Administrator`) rather than a hardcoded user GUID.

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
    operators/               # Wraps sei/crucible-operators (Keycloak + CNPG operators)
    infra/                   # Wraps sei/crucible-infra + local cert-manager CA chain
      templates/
        secret.yaml          # Gitea admin password (crucible-infra-gitea-admin)
        cert-manager.yaml    # Self-signed CA chain and crucible-cert certificate
    crucible/                # Wraps sei/crucible-apps + Gitea + MkDocs
      charts/gitea/          # Local Bitnami Gitea subchart
      files/mkdocs/          # MkDocs content seeded into Gitea on install
      templates/
        secret.yaml          # Gitea OIDC client secret (not in upstream realm)
        configmap.yaml       # Gitea env, MkDocs files, seed script
        job.yaml             # Gitea OIDC, MkDocs seed, gitea-client registration
    README.md                # Chart architecture documentation
  scripts/
    install-crucible.sh       # First-boot K3s install + Helm deploy
    configure-nic.sh         # First-boot network config
    enable-dev-mode.sh       # Optional: XFCE + VS Code + Tailscale
    setup-proxmox.sh         # Helper for Proxmox SSL/DNS configuration
docs/
  proxmox.md                 # Proxmox integration setup guide
```
