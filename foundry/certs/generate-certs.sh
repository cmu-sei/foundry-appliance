#!/bin/bash -e
#
# Copyright 2022 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.
#
# ./generate-certs.sh <gencert arguments>

KEYLENGTH=2048
ROOT_CA_DAYS=3650
INT_CA_DAYS=1825
HOST_DAYS=730

# Change to the current directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Generate root CA key and certificate
openssl genrsa -out root-ca-key.pem $KEYLENGTH
openssl req -new -key root-ca-key.pem -out root-ca.csr -config root-ca.cnf
openssl x509 -req -in root-ca.csr -signkey root-ca-key.pem -out root-ca.pem \
    -days $ROOT_CA_DAYS -extensions ca_ext -extfile root-ca.cnf

# Generate intermediate CA key and certificate
openssl genrsa -out int-ca-key.pem $KEYLENGTH
openssl req -new -key int-ca-key.pem -out int-ca.csr -config int-ca.cnf
openssl x509 -req -in int-ca.csr -CA root-ca.pem -CAkey root-ca-key.pem \
    -CAcreateserial -out int-ca.pem -days $INT_CA_DAYS -extensions intca_ext -extfile int-ca.cnf

# Generate host key and certificate
openssl genrsa -out host-key.pem $KEYLENGTH
openssl req -new -key host-key.pem -out host.csr -config host.cnf
openssl x509 -req -in host.csr -CA int-ca.pem -CAkey int-ca-key.pem \
    -CAcreateserial -out host.pem -days $HOST_DAYS -extensions server_ext -extfile host.cnf

# Create pkcs12 host bundle with full certificate chain
openssl pkcs12 -export -out host.pfx -inkey host-key.pem -in host.pem \
               -certfile int-ca.pem -certfile root-ca.pem \
               -passin pass:foundry -passout pass:foundry
sed -ri "s|(signer:) \"\"|\1 $(base64 -w0 host.pfx)|" ~/foundry/identity.values.yaml
