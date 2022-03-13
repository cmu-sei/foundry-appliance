#!/bin/bash -e
#
# Copyright 2022 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.

##############################
#   Foundry Stacks Install   #
##############################

# Change to the current directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Install stacks
common/install.sh
topomojo/install.sh

# Switch to common namespace
kubectl config set-context --current --namespace=common

# Create git repo to track changes
git init
git add *
git commit -m "Initial commit"
