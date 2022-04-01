#!/bin/bash
# 
# Copyright 2021 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.

#############################
#   Crucible Stack Install  #
#############################

# Change to the current directory
cd "$(dirname "${BASH_SOURCE[0]}")"
root_dir=/home/foundry
source ~/scripts/utils
MKDOCS_DIR=~/mkdocs
# Create crucible namespace and switch to it
kubectl apply -f namespace.yaml
kubectl config set-context --current --namespace=crucible

# Add host certificate
kubectl create secret tls appliance-cert --key ../certs/host-key.pem --cert <( cat ../certs/host.pem ../certs/int-ca.pem ) --dry-run=client -o yaml | kubectl apply -f -

# Add root ca
kubectl create secret generic appliance-root-ca --from-file=appliance-root-ca=../certs/root-ca.pem --dry-run=client -o yaml | kubectl apply -f -
kubectl create configmap appliance-root-ca --from-file=root-ca.crt=../certs/root-ca.pem --dry-run=client -o yaml | kubectl apply -f -

# Update coredns config
# export appliance_ip=$(ip route get 1 | awk '{print $(NF-2);exit}')
# export dns_server=${DNS_01:-8.8.8.8}
# envsubst < coredns-configmap.yaml | kubectl apply -n kube-system -f -
# kubectl rollout restart deployment/coredns -n kube-system

# dependancy installs
./setup-gitlab

hin_o --wait -u -p ../helm -f mongodb.values.yaml bitnami/mongodb
kubectl apply -f stackstorm-ingress.yaml
if [ -f $root_dir/crucible/vcenter.env ]; then 
  import_vars $root_dir/crucible/vcenter.env
  # decrypt Password
  VSPHERE_PASS=$(decrypt_string $VSPHERE_PASS)
  hin_o -r $root_dir/crucible/vcenter.env -p ../helm -u -v 1.4.0 -f steamfitter.values.yaml sei/steamfitter  
  hin_o -r $root_dir/crucible/vcenter.env -p ../helm -u -v 1.4.1 -f caster.values.yaml sei/caster
  #envsubst < stackstorm-min.values.yaml | helm upgrade --wait --install --timeout 10m -f - stackstorm stackstorm/stackstorm-ha
else
  hin_o -p ../helm -u -v 1.4.0 -f steamfitter.values.yaml sei/steamfitter  
  hin_o -p ../helm -u -v 1.4.1 -f caster.values.yaml sei/caster
fi


# Crucible Stack install
hin_o -r ../../appliance-vars -p ../helm -u -v 1.4.1 -f player.values.yaml sei/player
hin_o -r ../../appliance-vars -p ../helm -u -v 1.4.0 -f alloy.values.yaml sei/alloy
hin_o -u -p ../helm --version 0.80.0 --wait --timeout 10m -f stackstorm-min.values.yaml stackstorm/stackstorm-ha

# Add crucible docs to mkdocs-material
sed -i '/crucible.md/d' $MKDOCS_DIR/.gitignore
git -C $MKDOCS_DIR add -A || true
git -C $MKDOCS_DIR commit -m "Add Crucible Docs" || true
git -C $MKDOCS_DIR push -u https://administrator:foundry@foundry.local/gitea/foundry/mkdocs.git --all || true
