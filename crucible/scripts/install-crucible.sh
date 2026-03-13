#!/bin/bash
#
# Copyright 2025 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.
#
# Finalize Crucible stack on first boot

set -euo pipefail

FLAG=/etc/.install-crucible
CHARTS_DIR=/home/crucible/charts
RUN_AS_USER="sudo -u crucible"
APPLIANCE_VERSION=$(cat /etc/appliance_version)
CERT_MANAGER_VERSION=v1.20.0
export INSTALL_K3S_VERSION="v1.35.2+k3s1"

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
$RUN_AS_USER git config --global user.name "Crucible Administrator"
$RUN_AS_USER git config --global user.email "administrator@crucible.local"
$RUN_AS_USER git config --global init.defaultBranch main
$RUN_AS_USER git -C /home/crucible init
$RUN_AS_USER git -C /home/crucible add -A
$RUN_AS_USER git -C /home/crucible commit -am "Initial commit"

# Wait for network connectivity before downloading K3s
echo "Waiting for network connectivity..."
until curl -sf --max-time 5 https://get.k3s.io > /dev/null 2>&1; do
    echo "Network not ready, retrying in 5s..."
    sleep 5
done

# Install K3s during first boot to generate unique cluster CA
mkdir -p /etc/rancher/k3s
echo "nameserver 10.0.1.1" >>/etc/rancher/k3s/resolv.conf
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --resolv-conf /etc/rancher/k3s/resolv.conf" sh -
mkdir /home/crucible/.kube
cp /etc/rancher/k3s/k3s.yaml /home/crucible/.kube/config
chown -R crucible:crucible /home/crucible/.kube
sed -i 's/default/crucible/g' /home/crucible/.kube/config

# Wait for K3s API server to be ready before running kubectl
echo "Waiting for K3s API server..."
until $RUN_AS_USER kubectl get nodes &>/dev/null; do
    echo "K3s API not ready, retrying in 5s..."
    sleep 5
done

# Prep cluster and install Helm charts
$RUN_AS_USER kubectl create namespace crucible
$RUN_AS_USER kubectl config set-context --current --namespace=crucible
$RUN_AS_USER kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/$CERT_MANAGER_VERSION/cert-manager.crds.yaml

# Install infra chart (cert-manager, ingress, PostgreSQL, NFS, pgAdmin, secrets, realm)
$RUN_AS_USER helm install infra $CHARTS_DIR/infra --wait

# Wait for CA secret and PostgreSQL to be ready
$RUN_AS_USER timeout 300 bash -c 'while ! kubectl get secret infra-ca &>/dev/null; do echo "Waiting for infra-ca secret..."; sleep 5; done'
$RUN_AS_USER timeout 300 bash -c 'while ! kubectl get pods -l app.kubernetes.io/name=postgresql -o jsonpath="{.items[0].status.phase}" 2>/dev/null | grep -q Running; do echo "Waiting for PostgreSQL..."; sleep 5; done'

# Create CA cert ConfigMap from infra-ca secret (upstream chart certificateMap requires a ConfigMap)
$RUN_AS_USER kubectl get secret infra-ca -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/ca.crt
$RUN_AS_USER kubectl create configmap crucible-ca-cert --from-file=ca.crt=/tmp/ca.crt
rm -f /tmp/ca.crt

# Install crucible chart (Keycloak, all Crucible apps, Gitea, MkDocs)
$RUN_AS_USER helm install crucible $CHARTS_DIR/crucible --set global.version=$APPLIANCE_VERSION

# Create flag file
date > $FLAG
