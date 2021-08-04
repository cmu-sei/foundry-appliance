# Foundry Appliance

A virtual appliance for building cyber labs, challenges and competitions

## Overview

Foundry Appliance is a virtual machine that integrates cyber workforce development apps from the [Software Engineering Institute](https://www.sei.cmu.edu) at [Carnegie Mellon University](https://www.cmu.edu).

This project builds the virtual appliance using Ubuntu and [Microk8s](https://microk8s.io/)&mdash;a development Kubernetes environment. Pre-built OVA images are also available under [Releases](https://github.com/cmu-sei/foundry-appliance/releases).

## Getting Started

After deploying the appliance, visit https://foundry.local to begin using the apps.

## Apps

The following SEI apps are loaded on the appliance:

- [Identity](https://github.com/cmu-sei/identity) - OAuth2/OIDC identity provider
- [TopoMojo](https://github.com/cmu-sei/topomojo) - Virtual lab builder and player
- [Gameboard](https://github.com/cmu-sei/gameboard) - Competition manager

## Build

To build the appliance, you will need:

- [Packer](https://www.packer.io/)
- VMware hypervisor ([Fusion](https://www.vmware.com/products/fusion.html), [Workstation](https://www.vmware.com/products/workstation-pro.html), or [ESXi](https://www.vmware.com/products/vsphere-hypervisor.html))

Run the following command:

```
./build-appliance
```

### ESXi Build (optional)

To build the appliance using an ESXi server, create a file named `vsphere-vars.json` in this directory and add these settings:

```
{
  "vcenter_server": "<vCenter or ESXi FQDN>",
  "vcenter_username": "administrator@vsphere.local",
  "vcenter_password": "<password>",
  "cluster": "<cluster name (for vCenter only)>",
  "datastore": "<target datastore>"
}
```

To add these settings to the build, use this command:

```
./build-appliance -var-file vsphere-vars.json
```
