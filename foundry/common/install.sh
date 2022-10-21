#!/bin/bash -e
#
# Copyright 2022 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.

############################
#   Common Stack Install   #
############################

# Change to the current directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Create common namespace and switch to it
kubectl apply -f namespace.yaml
kubectl config set-context --current --namespace=common

# Add host certificate
kubectl create secret tls appliance-cert --key ../certs/host-key.pem --cert <( cat ../certs/host.pem ../certs/int-ca.pem )

# Install NFS server
helm repo add kvaps https://kvaps.github.io/charts
helm install -f nfs-server-provisioner.values.yaml nfs-server-provisioner kvaps/nfs-server-provisioner

# Install ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install --wait ingress-nginx ingress-nginx/ingress-nginx --values ingress-nginx.values.yaml

# Install PostgreSQL
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install --wait -f postgresql.values.yaml postgresql bitnami/postgresql

# Install pgAdmin4
helm repo add runix https://helm.runix.net/
kubectl create secret generic pgpassfile --from-literal=pgpassfile=postgresql:5432:\*:postgres:foundry
helm install -f pgadmin4.values.yaml pgadmin4 runix/pgadmin4

# Install code-server (browser-based VS Code)
helm repo add nicholaswilde https://nicholaswilde.github.io/helm-charts/
helm install -f code-server.values.yaml code-server nicholaswilde/code-server

# Kubernetes Dashboard
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm install -f kubernetes-dashboard.values.yaml kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard

# Add root CA to chart values
cat ../certs/root-ca.pem | sed 's/^/  /' | sed -i -re 's/(cacert:).*/\1 |-/' -e '/cacert:/ r /dev/stdin' mkdocs-material.values.yaml
cp ../certs/root-ca.pem ../../mkdocs/docs/root-ca.crt

# Install Gitea
git config --global init.defaultBranch main
helm repo add gitea https://dl.gitea.io/charts/
kubectl exec postgresql-0 -- psql 'postgresql://postgres:foundry@localhost' -c 'CREATE DATABASE gitea;'
helm install -f gitea.values.yaml gitea gitea/gitea
timeout 5m bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' https://foundry.local/gitea)" != "200" ]]; do sleep 5; done' || false
./setup-gitea

# Foundry Stack install
helm repo add sei https://helm.cyberforce.site/charts
helm install -f identity.values.yaml identity sei/identity
helm install -f mkdocs-material.values.yaml mkdocs-material sei/mkdocs-material
