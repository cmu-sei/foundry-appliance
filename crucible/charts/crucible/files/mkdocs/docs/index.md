# Crucible Appliance {{ .Values.global.version }}

Welcome to the **Crucible Appliance**. This virtual machine hosts workforce development apps from the [Software Engineering Institute](https://sei.cmu.edu) at [Carnegie Mellon University](https://cmu.edu).

## Getting started

The appliance advertises the _crucible.local_ domain via mDNS. All apps are served as subdirectories under this domain.

To get started using the virtual appliance:

1. Download [crucible-ca.crt](assets/crucible-ca.crt) and trust it in your keychain/certificate store. This removes browser certificate warnings.
2. Navigate to any of the apps in the following two sections.
3. Unless otherwise noted, the default credentials are:

   | key      | value      |
   | -------- | ---------- |
   | username | `crucible` |
   | password | `crucible` |

## Crucible apps

The following Crucible applications are loaded on this appliance:

| location                     | api                                                                 | description                                                                                                      |
| ---------------------------- | ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| [/alloy](/alloy)             | [api](/alloy/swagger)                                               | _Alloy_ coordinates Player, Caster, and Steamfitter into a single exercise launch.                               |
| [/blueprint](/blueprint)     | [api](/blueprint/swagger)                                           | _Blueprint_ is used for exercise planning and MSEL development.                                                  |
| [/caster](/caster)           | [api](/caster/swagger)                                              | _Caster_ provides automated infrastructure deployment using Terraform.                                           |
| [/cite](/cite)               | [api](/cite/swagger)                                                | _CITE_ (Collaborative Incident Threat Evaluator) supports incident evaluation during exercises.                  |
| [/gallery](/gallery)         | [api](/gallery/swagger)                                             | _Gallery_ enables information sharing and news feeds for exercise participants.                                  |
| [/gameboard](/gameboard)     | [api](/gameboard/api)                                               | _Gameboard_ provides a platform for cyber competition development and delivery.                                  |
| [/keycloak](/keycloak)       | [api](https://www.keycloak.org/docs-api/latest/rest-api/index.html) | _Keycloak_ manages logins/credentials across all of the apps. It can integrate with any OAuth2/OIDC application. |
| [/player](/player)           | [api](/player/swagger)                                              | _Player_ is the centralized interface where all other Crucible apps are consolidated for an exercise.            |
| [/steamfitter](/steamfitter) | [api](/steamfitter/swagger)                                         | _Steamfitter_ automates scenario tasks and injects during exercises.                                             |
| [/topomojo](/topomojo)       | [api](/topomojo/api)                                                | _TopoMojo_ allows users to build on-demand virtual labs.                                                         |
| [/vm](/vm)                   | [api](/vm/swagger)                                                  | _VM API_ provides virtual machine management within Player views.                                                |

## Third-party apps

The following third-party applications are loaded on this appliance:

| location           | description                                                                                           |
| ------------------ | ----------------------------------------------------------------------------------------------------- |
| [/gitea](/gitea)   | _Gitea_ provides a user interface for editing the web content on the appliance (including this page). |
| [/moodle](/moodle) | _Moodle_ is a learning management system for courseware delivery.                                     |

## Under the hood

For command line access to the appliance:

```
ssh crucible@crucible.local
```

The SSH password is `crucible`. Then you can run normal Kubernetes commands via `kubectl`.

```
kubectl get pods
```

The code for building this virtual machine is [available on GitHub](https://github.com/cmu-sei/foundry-appliance)

The appliance runs all of the apps in a single-host Kubernetes cluster provided by [K3s](https://k3s.io/). This provides a starting point for production-ready deployments in a datacenter or cloud.

![CMU SEI Unitmark](assets/cmu-sei-unitmark.png){: style="width:400px;margin:40px 0px 0px"}
