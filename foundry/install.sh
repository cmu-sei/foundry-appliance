#!/bin/bash -e
#
# Copyright 2022 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.

##############################
#   Foundry Stacks Install   #
##############################

# Change to the current directory
DIRECTORY="$(dirname "${BASH_SOURCE[0]}")"
cd $DIRECTORY
MKDOCS_DIR=~/mkdocs
mkdir -p $MKDOCS_DIR/hidden

apps="common,$1"
IFS=',' read -a stacks <<< $apps
echo "The following apps will be installed ${stacks[@]}"
# Always run common apps. 
for stack in ${stacks[@]}; do
  kubectl config set-context --current --namespace=$stack
  echo "Installing $stack with script located at $DIRECTORY/$stack/install.sh"
  $DIRECTORY/$stack/install.sh
done

# setup repo and push mkdocs
git -C $MKDOCS_DIR init || true
git -C $MKDOCS_DIR add -A || true
git -C $MKDOCS_DIR commit -m "Initial commit" || true
git -C $MKDOCS_DIR push -u https://administrator:foundry@foundry.local/gitea/foundry/mkdocs.git --all || true

# Create git repo to track changes
git init
git add *
git commit -m "Initial commit"
