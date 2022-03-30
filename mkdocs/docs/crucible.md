# Crucible

Welcome to the **Foundry Appliance**. This virtual machine hosts workforce development apps from the [Software Engineering Institute](https://sei.cmu.edu) at [Carnegie Mellon University](https://cmu.edu).

## Getting started

The appliance advertises the _foundry.local_ domain via mDNS. All apps are served as subdirectories under this domain.

To get started using the virtual appliance:

1. Download [root-ca.crt](root-ca.crt) and trust it in your keychain/certificate store. This removes browser certificate warnings.
2. Navigate to any of the apps in the following two sections.
3. Unless otherwise noted, the default credentials are:

   | key      | value                         |
   | -------- | ----------------------------- |
   | username | `administrator@foundry.local` |
   | password | `foundry`                     |
   | code     | `123456`                      |

## Setup vCenter

Crucible and its supporting apps require vCenter, This appliance provides a helper script to configure Crucible to use your vCenter infrastructure.

1. SSH into the foundry appliance
2. `cd ~/foundry/crucible`
3. `./setup-vcenter`

you will be asked a series of questions about your vCenter environment, additionally you will be asked if you would like to import example data.

## Example Data

Crucible is a powerful and complex application stack, to help get you started we've provided basic example content. If not already specified in the vcenter setup script you can import the example data separately

**WARNING: This is a destructive operation all current data will be replaced** {:style="color:red;"}

1. SSH into the foundry appliance
2. `cd ~/foundry/crucible`
3. `./import-content`

## Crucible apps

The following Foundry applications are loaded on this appliance:

| location                     | api                     | description                                                                                                                                                      |
| ---------------------------- | ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [/player](/player)           | [api](/player/api)      | _Player_ is the centralized interface where users, teams, and administrators go to participate in the cyber exercise.                                            |
| [/alloy](/alloy)             | [api](/alloy/api)       | _Alloy_ joins the other independent Crucible apps together to provide a complete Crucible experience (i.e. labs, on-demand exercises, exercises, etc.).          |
| [/caster](/caster)           | [api](/caster/api)      | _Caster_ provides a web interface that gives exercise developers a way to create, share, and manage topology configurations.                                     |
| [/steamfitter](/steamfitter) | [api](/steamfitter/api) | _Steamfitter_ creates scenarios consisting of a series of scheduled tasks, manual tasks, and injects which run against virtual machines in an exercise.delivery. |

## Third-party apps

The following third-party applications are loaded on this appliance:

| location                               | description                             |
| -------------------------------------- | --------------------------------------- |
| [gitlab](https://gitlab.foundry.local) | _Gitlab_ Module repo for caster         |
| [/stackstorm](/stackstorm)             | _Gitea_ Task processing for steamfitter |

![CMU SEI Unitmark](assets/cmu-sei-unitmark.png){: style="width:400px;margin:40px 0px 0px"}
