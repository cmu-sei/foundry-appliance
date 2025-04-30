#!/bin/bash -e
#
# Copyright 2025 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.

GITEA_ADMIN_PASSWORD=$(kubectl get secret gitea-admin-secret -o json | jq -r .data.password | base64 -d)
CURL_OPTS=( --silent --header "accept: application/json" --header "Content-Type: application/json" )
USER_TOKEN=$( curl "${CURL_OPTS[@]}" \
                --user administrator:$GITEA_ADMIN_PASSWORD \
                --request POST "https://foundry.local/gitea/api/v1/users/administrator/tokens" \
                --data '{
                    "name": "appliance-setup",
                    "scopes": ["write:organization"]
                }' | jq -r '.sha1'
)
MKDOCS_DIR=~/mkdocs

# Change to the current directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Set git user vars
git config --global user.name "Foundry Administrator"
git config --global user.email "administrator@foundry.local"

# Create foundry-docs organization
curl "${CURL_OPTS[@]}" \
  --request POST "https://foundry.local/gitea/api/v1/orgs?access_token=$USER_TOKEN" \
  --data @- <<EOF
{
  "username": "foundry",
  "repo_admin_change_team_access": true
}
EOF

# Create repo
curl "${CURL_OPTS[@]}" \
    --request POST "https://foundry.local/gitea/api/v1/orgs/foundry/repos?access_token=$USER_TOKEN" \
    --data @- <<EOF
{
  "name": "mkdocs",
  "private": false,
  "default_branch": "main"
}
EOF

git -C $MKDOCS_DIR init
git -C $MKDOCS_DIR add -A
git -C $MKDOCS_DIR commit -m "Initial commit"
git -C $MKDOCS_DIR push -u https://administrator:$GITEA_ADMIN_PASSWORD@foundry.local/gitea/foundry/mkdocs.git --all
