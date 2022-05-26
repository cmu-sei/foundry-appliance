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
source ~/scripts/utils
MKDOCS_DIR=~/mkdocs
import_vars ../../appliance-vars

# Add Helm repos and update
if [[ $(is_online) == true ]]; then
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo add runix https://helm.runix.net/
  helm repo add nicholaswilde https://nicholaswilde.github.io/helm-charts/
  helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo add gitea https://dl.gitea.io/charts/
  helm repo add kvaps https://kvaps.github.io/charts
  helm repo add sei https://helm.cyberforce.site/charts
  helm repo add stackstorm https://helm.stackstorm.com/
  helm repo add gitlab https://charts.gitlab.io
  helm repo add codecentric https://codecentric.github.io/helm-charts    
  helm repo update
fi

# Create common namespace and switch to it
kubectl apply -f namespace.yaml
kubectl config set-context --current --namespace=common

# Add host certificate
kubectl create secret tls appliance-cert --key ../certs/host-key.pem --cert <( cat ../certs/host.pem ../certs/int-ca.pem ) --dry-run=client -o yaml | kubectl apply -f -

# Add root ca
kubectl create secret generic appliance-root-ca --from-file=appliance-root-ca=../certs/root-ca.pem --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap appliance-root-ca --from-file=root-ca.crt=../certs/root-ca.pem --dry-run=client -o yaml | kubectl apply -f -

# Install NFS server
hin_o -r ../../appliance-vars -u -p ~/.helm -f nfs-server-provisioner.values.yaml kvaps/nfs-server-provisioner

# Install ingress-nginx
hin_o -r ../../appliance-vars -u -p ~/.helm -w -v 4.0.19 -f ingress-nginx.values.yaml ingress-nginx/ingress-nginx 

# Install PostgreSQL
hin_o -r ../../appliance-vars -u -p ~/.helm -w -v 11.1.28 -f postgresql.values.yaml bitnami/postgresql

# Install pgAdmin4
kubectl create secret generic pgpassfile --from-literal=pgpassfile=postgresql:5432:\*:postgres:foundry --dry-run=client -o yaml | kubectl apply -f -
hin_o -r ../../appliance-vars -u -p ~/.helm -f pgadmin4.values.yaml runix/pgadmin4

# Install code-server (browser-based VS Code)
hin_o -r ../../appliance-vars -u -p ~/.helm -f code-server.values.yaml nicholaswilde/code-server

# Kubernetes Dashboard
hin_o -r ../../appliance-vars -u -p ~/.helm -f kubernetes-dashboard.values.yaml kubernetes-dashboard/kubernetes-dashboard

# Add root CA to chart values
ed -s mkdocs-material.values.yaml <<< $'/cacert:/s/\"\"/|-/\n/cacert:/r !sed "s/^/  /" ../certs/root-ca.pem\nw'
cp ../certs/root-ca.pem ../../mkdocs/docs/root-ca.crt

# Install Gitea
git config --global init.defaultBranch main
kubectl exec postgresql-0 -- psql 'postgresql://postgres:foundry@localhost' -c 'CREATE DATABASE gitea;' || true
hin_o -r ../../appliance-vars -u -p ~/.helm -w -v 5.0.7 -f gitea.values.yaml gitea/gitea
echo "Waiting for gitea to become available"
timeout 5m bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' https://$DOMAIN/gitea)" != "200" ]]; do sleep 5; done' || false
./setup-gitea

#Foundry Stack install
if [ $OAUTH_PROVIDER = keycloak ]; then 
 kubectl create configmap keycloak-realm --from-file=realm.json=realm.json --dry-run=client -o yaml | kubectl apply -f -
 hin_o -u -r ../../appliance-vars -p ~/.helm -v 18.0.0 -f keycloak.values.yaml codecentric/keycloak
elif [ $OAUTH_PROVIDER = identity ]; then 
 hin_o -r ../../appliance-vars -u -v 0.2.0 -p ~/.helm -f identity.values.yaml sei/identity
fi

hin_o -r ../../appliance-vars -u -p ~/.helm -f mkdocs-material.values.yaml sei/mkdocs-material

# setup repo and push mkdocs
git -C $MKDOCS_DIR init || true
git -C $MKDOCS_DIR add -A || true
git -C $MKDOCS_DIR commit -m "Initial commit" || true
git -C $MKDOCS_DIR push -u https://administrator:foundry@$DOMAIN/gitea/foundry/mkdocs.git --all || true
