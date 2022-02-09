# Foundry Appliance

A virtual appliance for building cyber labs, challenges and competitions

## Overview

Foundry Appliance is a virtual machine that integrates cyber workforce development apps from the [Software Engineering Institute](https://www.sei.cmu.edu) at [Carnegie Mellon University](https://www.cmu.edu).

This project builds the virtual appliance using Ubuntu and [K3s](https://k3s.io/)&mdash;a lightweight Kubernetes environment. Pre-built OVA images are also available under [Releases](https://github.com/cmu-sei/foundry-appliance/releases).

The appliance comes in three flavors depnding on your use case. It can be built with the foundry applications, curcible applications or both.

## Getting Started

After deploying the appliance, visit https://foundry.local to begin using the apps. Or login using the VM console:

```
username: foundry
password: foundry
```

## Apps

The following SEI apps are loaded on the appliance:

- [Identity](https://github.com/cmu-sei/identity) - OAuth2/OIDC identity provider

### Foundry

- [TopoMojo](https://github.com/cmu-sei/topomojo) - Virtual lab builder and player
- [Gameboard](https://github.com/cmu-sei/gameboard) - Competition manager

### Crucible

- [Alloy]()
- [Caster]()
- [Player]()
- [Steamfitter]()

## Build

To build the appliance, you will need:

- [Packer](https://www.packer.io/) 1.7+
- A compatible hypervisor:
  - [VirtualBox](https://www.virtualbox.org/) (`virtualbox`)
  - [Fusion](https://www.vmware.com/products/fusion.html)/[Workstation](https://www.vmware.com/products/workstation-pro.html) (`vmware`)
  - [ESXi](https://www.vmware.com/products/vsphere-hypervisor.html) (`vsphere`)

### ESXi Build (optional)

To build the appliance using an ESXi server, create a file named `vsphere.auto.pkrvars.hcl` in this directory and add these settings:

```
vcenter_server    = "<vCenter or ESXi FQDN>"
vsphere_username  = "administrator@vsphere.local"
vsphere_password  = "<password>"
vsphere_cluster   = "<cluster>"    # vCenter only
vsphere_datastore = "<datastore>"
vsphere_network   = "<portgroup>"  # internet access required
```

### Build Command

Run the following command, where `<hypervisor>` is a comma-delimited list of target hypervisors and `<stack>` is a comma-delimited list of SEI application stacks:

```
./build-appliance <hypervisor> <stack>
```

For example, to build the appliance with Fusion or Workstation, run this command:

```
./build-appliance vmware foundry
```

To add VirtualBox to the previous build, run this command:

```
./build-appliance vmware,virtualbox foundry,crucible
```

[Packer `build` options](https://www.packer.io/docs/commands/build) can be appended to the end of the command. For example, this will save partial builds and automatically overwrite the previous build (useful for debugging):

```
./build-appliance <hypervisor> <apps> -on-error=abort -force
```

## Crucible - Configuration

Deploy the OVA in a network that can reach the vCenter server. Once powered on run the following commands. It is recomended you place the OVA on fast storage such as SSDs

`~/crucible/setup-vcenter`

You will be asked a series of questions about your infrastructure. This is to configure some of the crucible apps and optionally provide values for the example data.

## Crucible - Example Data

After configuration you may wish to import the example data. Be warned this is a destructive operation. Do not run this script if you have existing data on the appliance.

`~/crucible/import-content`

Follow the quick start instructions for access to the appliance.
