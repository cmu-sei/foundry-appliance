#!/bin/bash
#
# Copyright 2025 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.
#
# Finalize Foundry stack on first boot

FLAG=/etc/.install-foundry
CHARTS_DIR=/home/foundry/charts
RUN_AS_USER="sudo -u foundry"
APPLIANCE_VERSION=$(cat /etc/appliance_version)
CERT_MANAGER_VERSION=v1.17.2
export INSTALL_K3S_VERSION="v1.32.1+k3s1"

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

if [ -f $FLAG ]; then
    echo "$0 already executed. Delete $FLAG to run it again."
    exit 1
fi

# Create git repo to track changes
$RUN_AS_USER git config --global user.name "Foundry Administrator"
$RUN_AS_USER git config --global user.email "administrator@foundry.local"
$RUN_AS_USER git config --global init.defaultBranch main
$RUN_AS_USER git -C /home/foundry init
$RUN_AS_USER git -C /home/foundry add -A
$RUN_AS_USER git -C /home/foundry commit -am "Initial commit"

# Install K3s during first boot to generate unique cluster CA
mkdir -p /etc/rancher/k3s
echo "nameserver 10.0.1.1" >>/etc/rancher/k3s/resolv.conf
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --resolv-conf /etc/rancher/k3s/resolv.conf" sh -
mkdir /home/foundry/.kube
cp /etc/rancher/k3s/k3s.yaml /home/foundry/.kube/config
chown -R foundry:foundry /home/foundry/.kube
sed -i 's/default/foundry/g' /home/foundry/.kube/config

# Prep cluster and install Helm charts
$RUN_AS_USER kubectl create namespace foundry
$RUN_AS_USER kubectl config set-context --current --namespace=foundry
$RUN_AS_USER kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/$CERT_MANAGER_VERSION/cert-manager.crds.yaml
$RUN_AS_USER helm install infra $CHARTS_DIR/infra --wait
$RUN_AS_USER timeout 300 bash -c 'while ! kubectl get secret infra-ca &>/dev/null; do echo "Waiting for infra-ca secret..."; sleep 5; done'
$RUN_AS_USER helm install foundry $CHARTS_DIR/foundry --set global.version=$APPLIANCE_VERSION

# Create flag file
date > $FLAG
