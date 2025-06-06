#!/bin/bash -e
#
# Copyright 2025 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.
#
# Foundry Appliance Setup
#

# Exit on errors
set -euo pipefail

echo "$APPLIANCE_VERSION" >/etc/appliance_version

# Expand LVM volume to use full drive capacity
cp ~/scripts/expand-volume.sh /usr/local/bin/expand-volume
rm ~/scripts/expand-volume.sh
/usr/local/bin/expand-volume

# Disable swap for Kubernetes
swapoff -a
sed -i -r 's/(\/swap\.img.*)/#\1/' /etc/fstab

# Add Kubernetes apt repo
apt-get update
apt-get install -y apt-transport-https
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

# Add Helm apt repo
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg >/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list

# Upgrade existing packages to latest
apt-get update
apt-get full-upgrade -y

# Add foundry.local to hosts file
sed -i -r 's/(foundry)$/\1 foundry.local/' /etc/hosts

# Add dnsmasq resolver and other required packages
PRIMARY_INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
mkdir /etc/dnsmasq.d
cat <<EOF >/etc/dnsmasq.d/foundry.conf
bind-interfaces
listen-address=10.0.1.1
interface-name=foundry.local,$PRIMARY_INTERFACE
EOF

cat <<EOF >/etc/netplan/01-loopback.yaml
# Add loopback address for pods to use dnsmasq as upstream resolver
network:
  version: 2
  ethernets:
    lo:
      match:
        name: lo
      addresses:
        - 127.0.0.1/8:
            label: lo
        - 10.0.1.1/32:
            label: lo:host-access
        - ::1/128
EOF
chmod 600 /etc/netplan/01-loopback.yaml
netplan apply

# Install apt packages
apt-get install -y dnsmasq avahi-daemon nfs-common kubectl helm pwgen

# Install k-alias Kubernetes helper scripts
git clone https://github.com/jaggedmountain/k-alias.git /tmp/k-alias
cp /tmp/k-alias/[h,k]* /usr/local/bin

# Build dependencies for foundry Helm chart
for chart in infra foundry; do
  sudo -u $SSH_USERNAME helm dependency build ~/charts/$chart
done

# Customize MOTD and other text for the appliance
chmod -x /etc/update-motd.d/00-header
chmod -x /etc/update-motd.d/10-help-text
sed -i -r 's/(ENABLED=)1/\10/' /etc/default/motd-news
cp ~/scripts/display-banner.sh /etc/update-motd.d/05-display-banner
rm ~/scripts/display-banner.sh
echo -e "Foundry Appliance $APPLIANCE_VERSION \\\n \l \n" >/etc/issue

# Create systemd services to configure netplan primary interface and install Foundry chart
cp ~/scripts/configure-nic.sh /usr/local/bin/configure-nic
rm ~/scripts/configure-nic.sh
cat <<EOF >/etc/systemd/system/configure-nic.service
[Unit]
Description=Configure Netplan primary Ethernet interface (first boot)
After=network.target

[Service]
Type=oneshot
ExecStart=configure-nic
ExecStartPost=/bin/bash -c 'systemctl disable configure-nic.service'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cp ~/scripts/install-foundry.sh /usr/local/bin/install-foundry
rm ~/scripts/install-foundry.sh
cat <<EOF >/etc/systemd/system/install-foundry.service
[Unit]
Description=Install Foundry chart (first boot)
After=configure-nic.service
Requires=network-online.target

[Service]
Type=oneshot
ExecStart=install-foundry
ExecStartPost=/bin/bash -c 'systemctl disable install-foundry.service'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable configure-nic install-foundry

# Generate SSH key
sudo -u $SSH_USERNAME ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -N ''

# Restart mDNS daemon to avoid conflict with other hosts
systemctl restart avahi-daemon

# Delete Ubuntu machine ID for proper DHCP operation on deploy
echo -n >/etc/machine-id
