# Foundry Appliance

A virtual appliance for building cyber labs, challenges and competitions

## Overview

Foundry Appliance is a virtual machine that integrates cyber workforce development apps from the [Software Engineering Institute](https://www.sei.cmu.edu) at [Carnegie Mellon University](https://www.cmu.edu).

This project builds the virtual appliance using Ubuntu and [K3s](https://k3s.io/)&mdash;a lightweight Kubernetes environment. Pre-built OVA images are also available under [Releases](https://github.com/cmu-sei/foundry-appliance/releases).

## Getting Started

After deploying the appliance, visit https://foundry.local to begin using the apps. Or login using the VM console:

```
username: foundry  
password: foundry
```

## Apps

The following SEI apps are loaded on the appliance:

- [Identity](https://github.com/cmu-sei/identity) - OAuth2/OIDC identity provider
- [TopoMojo](https://github.com/cmu-sei/topomojo) - Virtual lab builder and player
- [Gameboard](https://github.com/cmu-sei/gameboard) - Competition manager

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

### Build Command

Run the following command, where `<hypervisor>` is a comma-delimited list of target hypervisors:

```
./build-appliance <hypervisor>
```

For example, to build the appliance with VirtualBox, run this command:

```
./build-appliance virtualbox
```

To add Proxmox to the previous build, run this command:

```
./build-appliance virtualbox,proxmox
```

[Packer `build` options](https://www.packer.io/docs/commands/build) can be appended to the end of the command. For example, this will save partial builds and automatically overwrite the previous build (useful for debugging):

```
./build-appliance <hypervisor> -on-error=abort -force
```
