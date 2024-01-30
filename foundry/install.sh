#!/bin/bash -e
#
# Copyright 2022 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.

#############################
#   Foundry Stack Install   #
#############################

GITEA_OAUTH_CLIENT_SECRET=$(openssl rand -hex 16)
GITEA_ADMIN_PASSWORD=$(pwgen 12)

# Change to the current directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Create foundry namespace and switch to it
kubectl apply -f namespace.yaml
kubectl config set-context --current --namespace=foundry

# Add host certificate
kubectl create secret tls appliance-cert --key certs/host-key.pem --cert <( cat certs/host.pem certs/int-ca.pem )

# Install NFS server
helm repo add kvaps https://kvaps.github.io/charts
helm install -f nfs-server-provisioner.values.yaml nfs-server-provisioner kvaps/nfs-server-provisioner --version 1.4.0

# Install ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install --wait ingress-nginx ingress-nginx/ingress-nginx --values ingress-nginx.values.yaml --version 4.4.2

# Install PostgreSQL
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install --wait -f postgresql.values.yaml postgresql bitnami/postgresql --version 12.1.14

# Install pgAdmin4
helm repo add runix https://helm.runix.net/
kubectl create secret generic pgpassfile --from-literal=pgpassfile=postgresql:5432:\*:postgres:foundry
helm install -f pgadmin4.values.yaml pgadmin4 runix/pgadmin4 --version 1.9.10

# Install code-server (browser-based VS Code)
helm repo add sei https://helm.cmusei.dev/charts
helm install -f code-server.values.yaml code-server sei/code-server --version 3.4.1

# Kubernetes Dashboard
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm install -f kubernetes-dashboard.values.yaml kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --version 6.0.0

# Add root CA to chart values
cat certs/root-ca.pem | sed 's/^/  /' | sed -i -re 's/(cacert:).*/\1 |-/' -e '/cacert:/ r /dev/stdin' mkdocs-material.values.yaml
cp certs/root-ca.pem ../mkdocs/docs/root-ca.crt

# Install Identity
sed -i -r "s/<GITEA_OAUTH_CLIENT_SECRET>/$GITEA_OAUTH_CLIENT_SECRET/" identity.values.yaml
helm install --wait -f identity.values.yaml identity sei/identity --version 0.2.2

# Install Gitea
git config --global init.defaultBranch main
helm repo add gitea https://dl.gitea.io/charts/
kubectl exec postgresql-0 -- psql 'postgresql://postgres:foundry@localhost' -c 'CREATE DATABASE gitea;'
kubectl create secret generic gitea-oauth-client --from-literal=key=gitea-client --from-literal=secret=$GITEA_OAUTH_CLIENT_SECRET
kubectl create secret generic gitea-admin-creds --from-literal=username=administrator --from-literal=password=$GITEA_ADMIN_PASSWORD
helm install -f gitea.values.yaml gitea gitea/gitea --version 7.0.2
timeout 5m bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' https://foundry.local/gitea)" != "200" ]]; do sleep 5; done' || false
./scripts/setup-gitea

# Install Material for MkDocs
helm install -f mkdocs-material.values.yaml mkdocs-material sei/mkdocs-material --version 0.1.0

# Add root CA to chart values
cat certs/root-ca.pem | sed 's/^/    /' | sed -i -re 's/(cacert:).*/\1 |-/' -e '/cacert:/ r /dev/stdin' gameboard.values.yaml
cat certs/root-ca.pem | sed 's/^/        /' | sed -i -re 's/(cacert.crt:).*/\1 |-/' -e '/cacert.crt:/ r /dev/stdin' topomojo.values.yaml

# Install TopoMojo
kubectl apply -f topomojo-pvc.yaml
helm install --wait -f topomojo.values.yaml topomojo sei/topomojo --version 0.3.8
kubectl apply -f console-ingress.yaml
sleep 60

# Add bot user to TopoMojo
TOPOMOJO_ACCESS_TOKEN=$(curl --silent --request POST \
  --url 'https://foundry.local/identity/connect/token' \
  --data grant_type=password \
  --data client_id=bootstrap-client \
  --data client_secret=foundry \
  --data username=administrator@foundry.local \
  --data password=foundry | jq -r '.access_token')

USER_ID=$(curl -X POST --silent \
  --url "https://foundry.local/topomojo/api/user" \
  -H "Authorization: Bearer $TOPOMOJO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "name": "bot-gameboard", "role": "user", "scope": "gameboard" }' | jq -r '.id')

API_KEY=$(curl -X POST --silent \
  --url "https://foundry.local/topomojo/api/apikey/$USER_ID" \
  -H "Authorization: Bearer $TOPOMOJO_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{}" | jq -r '.value')

# Install Gameboard
sed -i -r "s/(Core__GameEngineClientSecret:).*/\1 $API_KEY/" gameboard.values.yaml
helm install --wait -f gameboard.values.yaml gameboard sei/gameboard --version 0.4.4

# Add administrator user to Gameboard
timeout 5m bash -c 'until kubectl exec postgresql-0 -n foundry -- env PGPASSWORD=foundry psql -lqt -U postgres | cut -d \| -f 1 | grep -qw gameboard; do sleep 5; done' || false
sleep 5
kubectl exec postgresql-0 -n foundry -- psql 'postgresql://postgres:foundry@localhost/gameboard' -c "INSERT INTO \"Users\" (\"Id\",\"Name\",\"ApprovedName\",\"Role\") VALUES ('dee684c5-2eaf-401a-915b-d3d4320fe5d5', 'Administrator', 'Administrator', 63);"

# Create git repo to track changes
git init
git add *
git commit -m "Initial commit"
