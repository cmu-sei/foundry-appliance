# Crucible Appliance

A virtual appliance for building cyber labs, challenges and competitions

## Overview

Crucible Appliance is a virtual machine that integrates cyber workforce development apps from the [Software Engineering Institute](https://www.sei.cmu.edu) at [Carnegie Mellon University](https://www.cmu.edu).

This project builds the virtual appliance using Ubuntu and [K3s](https://k3s.io/)&mdash;a lightweight Kubernetes environment. Pre-built OVA images are also available under [Releases](https://github.com/cmu-sei/foundry-appliance/releases).

## Getting Started

After deploying the appliance, visit https://crucible.local to begin using the apps. Or login using the VM console:

```
username: crucible
password: crucible
```

## Apps

The following apps are deployed on the appliance, all accessible under `https://crucible.local`:

| App | Path | Description |
|-----|------|-------------|
| [Keycloak](https://www.keycloak.org/) | `/keycloak` | OIDC identity provider |
| [TopoMojo](https://github.com/cmu-sei/topomojo) | `/topomojo` | Virtual lab builder and player |
| [Gameboard](https://github.com/cmu-sei/gameboard) | `/gameboard` | Competition manager |
| [Player](https://github.com/cmu-sei/crucible/wiki/player) | `/player` | Exercise presentation platform |
| [Alloy](https://github.com/cmu-sei/crucible/wiki/alloy) | `/alloy` | Just-in-time lab deployment |
| [Blueprint](https://github.com/cmu-sei/crucible/wiki/blueprint) | `/blueprint` | Exercise template editor |
| [Caster](https://github.com/cmu-sei/crucible/wiki/caster) | `/caster` | Infrastructure-as-code environment |
| [CITE](https://github.com/cmu-sei/crucible/wiki/cite) | `/cite` | Incident tabletop evaluator |
| [Gallery](https://github.com/cmu-sei/crucible/wiki/gallery) | `/gallery` | Information feed and reporting |
| [Steamfitter](https://github.com/cmu-sei/crucible/wiki/steamfitter) | `/steamfitter` | Scripted scenario automation |
| [Moodle](https://moodle.org/) | `/moodle` | Learning management system |
| [Gitea](https://gitea.io/) | `/gitea` | Git server for content hosting |
| [MkDocs](https://www.mkdocs.org/) | `/start` | Documentation site |
| [pgAdmin](https://www.pgadmin.org/) | `/pgadmin` | PostgreSQL database management |

## Helm Charts

The appliance uses a two-chart deployment model installed into the `crucible` namespace:

1. **`infra`** — Infrastructure chart; installs cert-manager (self-signed CA), ingress-nginx, PostgreSQL, NFS storage provisioner, pgAdmin, and all pre-created secrets.
2. **`crucible`** — Application chart; wraps the upstream `sei/crucible` chart (Keycloak + all Crucible apps) along with Gitea and MkDocs as subchart dependencies.

To upgrade the charts after modifying values or templates on a deployed appliance:

```bash
helm upgrade -n crucible infra /home/crucible/charts/infra
helm upgrade -n crucible crucible /home/crucible/charts/crucible --set global.version=$(cat /etc/appliance_version)
```

See [`crucible/charts/README.md`](crucible/charts/README.md) for detailed chart architecture documentation.

## Build

To build the appliance, you will need:

- [Packer](https://www.packer.io/) 1.7+
- A compatible hypervisor:
  - [VirtualBox](https://www.virtualbox.org/) (`virtualbox`)
  - [Proxmox Virtual Environment](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview) (`proxmox`)

### Proxmox Build (optional)

To build the appliance using Proxmox, create a file named `proxmox.auto.pkrvars.hcl` in this directory and add these settings:

```
proxmox_url      = "https://<proxmox.fqdn>:8006/api2/json" # replace with your PVE server
proxmox_user     = "root@pam"
proxmox_password = "<password>"
proxmox_node     = "pve.lan" # replace with the Proxmox node name that should build the appliance
```

### Build Script

Run the following command, where `<hypervisor>` is a comma-delimited list of target hypervisors:

```
./build-appliance.sh <hypervisor>
```

For example, to build the appliance with VirtualBox, run this command:

```
./build-appliance.sh virtualbox
```

To add Proxmox to the previous build, run this command:

```
./build-appliance.sh virtualbox,proxmox
```

[Packer `build` options](https://www.packer.io/docs/commands/build) can be appended to the end of the command. For example, this will save partial builds and automatically overwrite the previous build (useful for debugging):

```
./build-appliance.sh <hypervisor> -on-error=abort -force
```

### CD-ROM Autoinstall (`use_cidata`)

By default, Packer starts a local HTTP server to serve the Ubuntu autoinstall configuration. This requires the target hypervisor to have network access back to the machine running Packer.

If you are building from an environment where the hypervisor cannot reach Packer's HTTP server (e.g., a dev container, a CI runner behind NAT, or a remote Proxmox host), set `use_cidata` to deliver the autoinstall data via a mounted CD-ROM instead:

```
./build-appliance.sh proxmox -var use_cidata=true
```

Or add it to your `proxmox.auto.pkrvars.hcl`:

```
use_cidata = true
```
