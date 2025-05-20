#!/bin/bash -e
#
# Copyright 2025 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.
#
# Foundry Appliance Setup
#

echo "$APPLIANCE_VERSION" >/etc/appliance_version

# Expand LVM volume to use full drive capacity
~/foundry/scripts/expand-volume.sh

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
apt-get install -y dnsmasq avahi-daemon nfs-common sshpass kubectl helm pwgen build-essential

# Install VirtualBox Guest Additions
if [ -f ~/VBoxGuestAdditions.iso ]; then
  mount -o loop,ro ~/VBoxGuestAdditions.iso /mnt
  /mnt/VBoxLinuxAdditions.run
  umount /mnt
  rm ~/VBoxGuestAdditions.iso
fi

# Install k3s
mkdir -p /etc/rancher/k3s
echo "nameserver 10.0.1.1" >>/etc/rancher/k3s/resolv.conf
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.32.1+k3s1" INSTALL_K3S_EXEC="--disable traefik --resolv-conf /etc/rancher/k3s/resolv.conf --embedded-registry" sh -
sudo -u $SSH_USERNAME mkdir ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i 's/default/foundry/g' ~/.kube/config
chown $SSH_USERNAME:$SSH_USERNAME ~/.kube/config

# Install nerdctl for managing containerd
wget -q0- https://github.com/containerd/nerdctl/releases/download/v2.1.2/nerdctl-2.1.2-linux-amd64.tar.gz | tar xvf /tmp
cp /tmp/nerdctl /usr/local/bin

# Populate K3s registry mirror
CHART_DIR=/home/foundry/foundry/charts/foundry
OUTPUT_DIR=/var/lib/rancher/k3s/agent/images/
mkdir -p $OUTPUT_DIR
sudo -u $SSH_USERNAME helm dependency build $CHART_DIR
IMAGES=$(helm template $CHART_DIR | grep -E '^\s+image:' | awk '{print $2}' | sed 's/"//g' | sed "s/'//g" | sort | uniq)
for IMAGE in $IMAGES; do
  CLEAN_NAME=$(echo "$IMAGE" | tr '/' '_' | tr ':' '-' | sed 's/@.*$//')
  FILENAME="${OUTPUT_DIR}/${CLEAN_NAME}.tar.zst"
  nerdctl pull "$IMAGE"
  nerdctl save "$IMAGE" | zstd > "$FILENAME"
  nerdctl rmi -f "$IMAGE"
done

# Install k-alias Kubernetes helper scripts
sudo -u $SSH_USERNAME git clone https://github.com/jaggedmountain/k-alias.git
(cd /usr/local/bin && ln -s ~/k-alias/[h,k]* .)

# Customize MOTD and other text for the appliance
chmod -x /etc/update-motd.d/00-header
chmod -x /etc/update-motd.d/10-help-text
sed -i -r 's/(ENABLED=)1/\10/' /etc/default/motd-news
cp ~/foundry/scripts/display-banner.sh /etc/update-motd.d/05-display-banner
rm ~/foundry/scripts/display-banner.sh
sed -i "s/{version}/$APPLIANCE_VERSION/" ~/mkdocs/docs/index.md
echo -e "Foundry Appliance $APPLIANCE_VERSION \\\n \l \n" >/etc/issue

# Create systemd service to configure netplan primary interface
mv /home/foundry/foundry/scripts/configure-nic.sh /usr/local/bin/configure-nic
cat <<EOF >/etc/systemd/system/configure-nic.service
[Unit]
Description=Configure Netplan primary Ethernet interface
After=network.target
Before=k3s.service

[Service]
Type=oneshot
ExecStart=configure-nic

[Install]
WantedBy=multi-user.target
EOF
systemctl enable configure-nic

# Generate SSH key
sudo -u $SSH_USERNAME ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -N ''

# Generate CA and host certificates
sudo -u $SSH_USERNAME ~/foundry/certs/generate-certs.sh -loglevel 3

# Add newly generated CA certificate to trusted roots
cp ~/foundry/certs/ca.pem /usr/local/share/ca-certificates/foundry-appliance-ca.crt
update-ca-certificates

# Restart mDNS daemon to avoid conflict with other hosts
systemctl restart avahi-daemon

# Delete Ubuntu machine ID for proper DHCP operation on deploy
echo -n >/etc/machine-id
