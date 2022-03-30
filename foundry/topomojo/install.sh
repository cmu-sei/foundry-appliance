#!/bin/bash -e
#
# Copyright 2022 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.

##############################
#   TopoMojo Stack Install   #
##############################

# Change to the current directory
cd "$(dirname "${BASH_SOURCE[0]}")"
MKDOCS_DIR=~/mkdocs
# Create topomojo namespace and switch to it
kubectl apply -f namespace.yaml
kubectl config set-context --current --namespace=topomojo

# Add host certificate
kubectl create secret tls appliance-cert --key ../certs/host-key.pem --cert <( cat ../certs/host.pem ../certs/int-ca.pem )

# Add root CA to chart values
ed -s gameboard.values.yaml <<< $'/cacert:/s/\"\"/|-/\n/cacert:/r !sed "s/^/    /" ../certs/root-ca.pem\nw'
ed -s topomojo.values.yaml <<< $'/cacert.crt:/s/\"\"/|-/\n/cacert.crt:/r !sed "s/^/        /" ../certs/root-ca.pem\nw'

# Install TopoMojo
kubectl apply -f topomojo-pvc.yaml
helm install --wait -f topomojo.values.yaml topomojo sei/topomojo
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
helm install --wait -f gameboard.values.yaml gameboard sei/gameboard

# Add administrator user to Gameboard
timeout 5m bash -c 'until kubectl exec postgresql-0 -n common -- env PGPASSWORD=foundry psql -lqt -U postgres | cut -d \| -f 1 | grep -qw gameboard; do sleep 5; done' || false
sleep 5
kubectl exec postgresql-0 -n common -- psql 'postgresql://postgres:foundry@localhost/gameboard' -c "INSERT INTO \"Users\" (\"Id\",\"Name\",\"ApprovedName\",\"Role\") VALUES ('dee684c5-2eaf-401a-915b-d3d4320fe5d5', 'Administrator', 'Administrator', 63);"

# Add TopoMojo docs to mkdocs-material
sed -i '/topomojo.md/d' $MKDOCS_DIR/.gitignore
git -C $MKDOCS_DIR add -A || true
git -C $MKDOCS_DIR commit -m "Add Topomojo docs" || true
git -C $MKDOCS_DIR push -u https://administrator:foundry@foundry.local/gitea/foundry/mkdocs.git --all || true
