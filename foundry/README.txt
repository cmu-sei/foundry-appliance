========================
Foundry Appliance README
========================

This virtual appliance installs two Helm charts, 'infra' and 'foundry', from
the ~/charts directory. Internet access via DHCP is required on first boot.

To see the status of the install:
    systemctl status install-foundry

Logs for the install script:
    journalctl -u install-foundry

The install process takes roughly three (3) minutes. Once it completes, you
should see a number of Kubernetes pods running in the 'foundry' namespace
(the default namespace for this user on first login):
    kubectl get pods

Once all of the pods have a status of [Running|Completed], you can load the
appliance landing page at https://foundry.local in a browser.
