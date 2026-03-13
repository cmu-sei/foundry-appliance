Copyright 2025 Carnegie Mellon University.
Released under a BSD (SEI)-style license, please see LICENSE.md in the
project root or contact permission@sei.cmu.edu for full terms.

# Crucible Appliance Helm Charts

This virtual appliance installs two Helm charts, [infra](charts/infra/) and [crucible](charts/crucible/), from
the [charts](charts/) directory. **Internet access via DHCP is required on first boot.**

To see the status of the install:

```bash
systemctl status install-crucible
```

Logs for the install script:

```bash
journalctl -u install-crucible
```

The install process takes roughly three (3) minutes. Once it completes, you
should see a number of Kubernetes pods running in the `crucible` namespace
(the default namespace for this user on first login):

```bash
kubectl get pods
```

Once all of the pods have a status of [Running|Completed], you can load the
appliance landing page at https://crucible.local in a browser.

## `charts/infra/`

Infrastructure and all pre-created secrets. Installed first because
everything else depends on it.

- **TLS** - Self-signed ClusterIssuer, 10-year CA Certificate, CA ClusterIssuer, `crucible-cert` domain Certificate
- **Database** - PostgreSQL Database
- **Storage** - NFS server provisioner + PVCs for TopoMojo, Gameboard, and Caster
- **Ingress** - ingress-nginx controller (all apps path-routed under `crucible.local`)

## `charts/crucible/`

A local Helm chart with three subchart dependencies:

- **`sei-crucible`** (alias for upstream [sei/crucible](https://github.com/cmu-sei/helm-charts/tree/main/charts/crucible)) — Keycloak + all Crucible applications
  - Wraps the upstream `sei/crucible` chart
  - Fills in empty upstream defaults: TLS `secretName: crucible-cert`, OIDC authorities
  - Configures Gitea with OIDC via a post-install Job
  - Seeds MkDocs content into Gitea via a post-install Job
  - Creates the default `crucible` user in Keycloak via a post-install Job
- **`gitea`** (local subchart) — Git server at `/gitea`
- **`mkdocs-material`** (from sei repo) — Documentation site at `/start`
