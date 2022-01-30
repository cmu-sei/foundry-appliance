#!/bin/bash -e
#
# Copyright 2022 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.
#
# install-cert-esxi.sh
#
# Installs Foundry Appliance certificate and key onto an ESXi server

ESXI_USER=root
ESXI_HOSTNAME=esxi.foundry.local

if [[ ! $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo -e "\nUsage: $0 [esxi ip address]\n"
  exit 1
fi

read -s -p "ESXi $ESXI_USER password: " password
echo
echo $password

rui_crt=$(cat host.pem int-ca.pem)
rui_key=$(<host-key.pem)
echo "$rui_crt"
echo "$rui_key"
