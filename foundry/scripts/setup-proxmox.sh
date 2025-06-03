#! /bin/bash

# WIP script for Proxmox initialization for the Foundry Appliance and TopoMojo
#
# Currently only updates DNS and certificates for the appliance and the Proxmox node.
# Looking to add Proxmox, NGINX, and TopoMojo configuration.
# -Sebastian Babon

set -euo pipefail

RUI_CRT=$(< /home/foundry/foundry/certs/host.pem)
RUI_KEY=$(< /home/foundry/foundry/certs/host-key.pem)
PROXMOX_CERTDIR="/etc/pve/nodes/proxmox"
PROXMOX_HOSTNAME="proxmox.foundry.local"
PROXMOX_USER="root"
HOSTS_FILE="/etc/hosts"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <proxmox-ip>"
  exit 1
fi

PROXMOX_IP="$1"

# Update local /etc/hosts
echo -e "\n*** If prompted, type your SUDO password. ***\n"
if grep -q "${PROXMOX_HOSTNAME}" "${HOSTS_FILE}"; then
  sudo sed -i -r "s/.*(${PROXMOX_HOSTNAME})/${PROXMOX_IP} \1/" "${HOSTS_FILE}"
  echo -e "\n${PROXMOX_HOSTNAME} (${PROXMOX_IP}) updated in ${HOSTS_FILE}"
else
  echo "${PROXMOX_IP} ${PROXMOX_HOSTNAME}" | sudo tee -a "${HOSTS_FILE}" > /dev/null
  echo -e "\n${PROXMOX_HOSTNAME} (${PROXMOX_IP}) added to ${HOSTS_FILE}"
fi

sudo systemctl restart dnsmasq
echo -e "\ndnsmasq restarted."

# Update remote Proxmox hostname and hosts file
ssh "${PROXMOX_USER}@${PROXMOX_HOSTNAME}" << EOF
set -e

hostnamectl set-hostname "${PROXMOX_HOSTNAME}"

echo "${PROXMOX_HOSTNAME}" > /etc/hostname

if grep -q "${PROXMOX_HOSTNAME}" /etc/hosts; then
    sed -i "s/^.*${PROXMOX_HOSTNAME}.*/${PROXMOX_IP} ${PROXMOX_HOSTNAME} proxmox/" /etc/hosts
else
    echo "${PROXMOX_IP} ${PROXMOX_HOSTNAME} proxmox" >> /etc/hosts
fi

hostnamectl

if [ ! -f "${PROXMOX_CERTDIR}/pve-ssl.pem.orig" ]; then
    cp "${PROXMOX_CERTDIR}/pve-ssl.pem" "${PROXMOX_CERTDIR}/pve-ssl.pem.orig"
fi
echo "${RUI_CRT}" > "${PROXMOX_CERTDIR}/pve-ssl.pem"

if [ ! -f "${PROXMOX_CERTDIR}/pve-ssl.key.orig" ]; then
    cp "${PROXMOX_CERTDIR}/pve-ssl.key" "${PROXMOX_CERTDIR}/pve-ssl.key.orig"
fi
echo "${RUI_KEY}" > "${PROXMOX_CERTDIR}/pve-ssl.key"

systemctl restart nginx
systemctl restart pveproxy pvedaemon
EOF
