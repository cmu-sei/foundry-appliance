#!/bin/bash -e
#
# Copyright 2025 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.
#
# Generate CA and host certificates for the Foundry Appliance

CURVE="secp384r1"
CA_DAYS=3650
HOST_DAYS=730

# Change to the current directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Generate root CA key and certificate
openssl ecparam -name $CURVE -genkey -out ca-key.pem
openssl req -new -key ca-key.pem -out ca.csr -config ca.cnf
openssl x509 -req -in ca.csr -signkey ca-key.pem -out ca.pem \
    -days $CA_DAYS -extensions ca_ext -extfile ca.cnf

# Generate host key and certificate
openssl ecparam -name $CURVE -genkey -out host-key.pem $KEYLENGTH
openssl req -new -key host-key.pem -out host.csr -config host.cnf
openssl x509 -req -in host.csr -CA ca.pem -CAkey ca-key.pem \
    -CAcreateserial -out host.pem -days $HOST_DAYS -extensions server_ext -extfile host.cnf
