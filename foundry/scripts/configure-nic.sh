#!/bin/bash
#
# Copyright 2025 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.
#
# Configure netplan and dnsmasq to use first Ethernet interface

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

PRIMARY_ETH=$(find /sys/class/net/en* -type l -printf "%f\n" | head -n 1)
DNSMASQ_CONF=/etc/dnsmasq.d/foundry.conf
NETPLAN_CONF=/etc/netplan/50-cloud-init.yaml
FLAG=/etc/.configure-nic

if [ ! -f "$FLAG" ]; then
    sed -i -r "s/en.*:/$PRIMARY_ETH:/" $NETPLAN_CONF
    netplan apply
    sed -i -r "s/(foundry.local,).*/\1$PRIMARY_ETH/" $DNSMASQ_CONF
    systemctl restart dnsmasq
    date > $FLAG
    echo "$PRIMARY_ETH configured as primary Ethernet interface."
else
    echo "Configuration skipped. Delete $FLAG to reconfigure the primary interface."
fi
