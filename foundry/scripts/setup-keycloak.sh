#!/bin/bash -e

# W.I.P Keycloak Setup Script for the Foundry Appliance

# Configuration parameters
export KEYCLOAK_SERVER_URL="https://foundry.local/auth"
export REALM_NAME="master"
export KEYCLOAK_ADMIN_USER="foundry"
export KEYCLOAK_ADMIN_PASSWORD="foundry"

# Wait until Keycloak is available
echo "Waiting for Keycloak to be available at ${KEYCLOAK_SERVER_URL}..."

until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' "${KEYCLOAK_SERVER_URL}")" == "303" ]]; do
    echo "Keycloak not available yet, sleeping 5 seconds..."
    sleep 5
done

echo "Keycloak is available. Continuing configuration."

# Get the access token
TOKEN=$(curl -k -s -X POST "${KEYCLOAK_SERVER_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${KEYCLOAK_ADMIN_USER}" \
  -d "password=${KEYCLOAK_ADMIN_PASSWORD}" \
  -d 'grant_type=password' \
  -d 'client_id=admin-cli' | jq -r '.access_token')

# Function to check and create client scopes with audience and sub claim mappers
ensure_client_scope_with_mappers() {
  local SCOPE_NAME="$1"
  local CLIENT_AUDIENCE="$2"
  local DESCRIPTION="$3"

  echo "Ensuring client scope '$SCOPE_NAME' with mappers..."

  # Check if the scope exists
  SCOPE_ID=$(curl -k -s "${KEYCLOAK_SERVER_URL}/admin/realms/${REALM_NAME}/client-scopes" \
    -H "Authorization: Bearer $TOKEN" | jq -r --arg NAME "$SCOPE_NAME" '.[] | select(.name == $NAME) | .id')

  if [[ -z "$SCOPE_ID" ]]; then
    # Create the scope with mappers
    echo "Scope '$SCOPE_NAME' does not exist. Creating with audience and sub claim mappers..."
    curl -k -s -X POST "${KEYCLOAK_SERVER_URL}/admin/realms/${REALM_NAME}/client-scopes" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "'"$SCOPE_NAME"'",
        "description": "'"$DESCRIPTION"'",
        "protocol": "openid-connect",
        "attributes": {
          "include.in.token.scope": "true",
          "display.on.consent.screen": "true"
        },
        "protocolMappers": [
          {
            "name": "audiences",
            "protocol": "openid-connect",
            "protocolMapper": "oidc-audience-mapper",
            "consentRequired": false,
            "config": {
              "included.client.audience": "'"$CLIENT_AUDIENCE"'",
              "id.token.claim": "false",
              "access.token.claim": "true"
            }
          },
          {
            "name": "subject",
            "protocol": "openid-connect",
            "protocolMapper": "oidc-sub-mapper",
            "consentRequired": false,
            "config": {
              "access.token.claim": "true",
              "id.token.claim": "true",
              "userinfo.token.claim": "true"
            }
          }
        ]
      }'
    # Refresh scope ID after creation
    SCOPE_ID=$(curl -k -s "${KEYCLOAK_SERVER_URL}/admin/realms/${REALM_NAME}/client-scopes" \
      -H "Authorization: Bearer $TOKEN" | jq -r --arg NAME "$SCOPE_NAME" '.[] | select(.name == $NAME) | .id')
  else
    echo "Scope '$SCOPE_NAME' already exists."
  fi

  # Attach scope to audience client as a default client scope
  CLIENT_ID=$(curl -k -s "${KEYCLOAK_SERVER_URL}/admin/realms/${REALM_NAME}/clients?clientId=${CLIENT_AUDIENCE}" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')

  if [[ -n "$CLIENT_ID" ]]; then
    echo "Attaching scope '$SCOPE_NAME' to client '$CLIENT_AUDIENCE' as a default scope..."
    curl -k -X PUT "${KEYCLOAK_SERVER_URL}/admin/realms/${REALM_NAME}/clients/${CLIENT_ID}/default-client-scopes/${SCOPE_ID}" \
      -H "Authorization: Bearer $TOKEN" || true
  else
    echo "Client '$CLIENT_AUDIENCE' not found. Skipping scope attachment."
  fi
}

# Create API scopes with mappers and attach to clients
ensure_client_scope_with_mappers "topomojo-api" "topomojo-api" "TopoMojo API"
ensure_client_scope_with_mappers "gameboard-api" "gameboard-api" "Gameboard API"

# Create clients
for CLIENT_JSON in \
  '{
    "clientId": "bootstrap-client",
    "name": "Bootstrap",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": false,
    "secret": "foundry",
    "standardFlowEnabled": false,
    "directAccessGrantsEnabled": true,
    "serviceAccountsEnabled": false,
    "defaultClientScopes": [
      "openid",
      "profile",
      "topomojo-api"
    ]
  }' \
  '{
    "clientId": "topomojo-client",
    "name": "TopoMojo",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": true,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": false,
    "redirectUris": [
      "https://foundry.local/topomojo/oidc",
      "https://foundry.local/topomojo/oidc-silent.html"
    ],
    "baseUrl": "https://foundry.local/topomojo",
    "defaultClientScopes": [
      "openid",
      "profile",
      "topomojo-api"
    ],
    "attributes": {
      "pkce.code.challenge.method": "S256",
      "post.logout.redirect.uris": "https://foundry.local/topomojo"
    }
  }' \
  '{
    "clientId": "topomojo-swagger",
    "name": "TopoMojo Swagger",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": true,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": false,
    "redirectUris": [
      "https://foundry.local/topomojo/api/oauth2-redirect.html"
    ],
    "baseUrl": "https://foundry.local/topomojo/api",
    "defaultClientScopes": [
      "openid",
      "profile",
      "topomojo-api"
    ],
    "attributes": {
      "consent.required": "true",
      "post.logout.redirect.uris": "https://foundry.local/topomojo/api"
    }
  }' \
  '{
    "clientId": "gameboard-client",
    "name": "Gameboard",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": true,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": false,
    "redirectUris": [
      "https://foundry.local/gameboard/oidc",
      "https://foundry.local/gameboard/oidc-silent.html"
    ],
    "baseUrl": "https://foundry.local/gameboard",
    "defaultClientScopes": [
      "openid",
      "profile",
      "organization",
      "gameboard-api"
    ],
    "attributes": {
      "pkce.code.challenge.method": "S256",
      "post.logout.redirect.uris": "https://foundry.local/gameboard"
    }
  }' \
  '{
    "clientId": "gameboard-swagger",
    "name": "GameBoard Swagger",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": true,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": false,
    "redirectUris": [
      "https://foundry.local/gameboard/api/oauth2-redirect.html"
    ],
    "baseUrl": "https://foundry.local/gameboard/api",
    "defaultClientScopes": [
      "openid",
      "profile",
      "gameboard-api"
    ],
    "attributes": {
      "consent.required": "true",
      "post.logout.redirect.uris": "https://foundry.local/gameboard/api"
    }
  }' \
  '{
    "clientId": "gitea-client",
    "name": "Gitea",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": false,
    "secret": "a92de95c865db308dfa5b7a098f45a7f",
    "standardFlowEnabled": true,
    "directAccessGrantsEnabled": false,
    "implicitFlowEnabled": false,
    "redirectUris": [
      "https://foundry.local/gitea/user/oauth2/Foundry/callback"
    ],
    "baseUrl": "https://foundry.local/gitea",
    "defaultClientScopes": [
      "openid",
      "profile",
      "email"
    ],
    "attributes": {
      "post.logout.redirect.uris": "https://foundry.local/gitea",
      "oauth2.device.authorization.grant.enabled": "false"
    }
  }'

do
  CLIENT_ID=$(echo "$CLIENT_JSON" | jq -r .clientId)
  echo "Creating client: $CLIENT_ID"
  curl -k -X POST "${KEYCLOAK_SERVER_URL}/admin/realms/${REALM_NAME}/clients" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$CLIENT_JSON"
done

# Create default Foundry user
echo "Creating default user 'administrator'..."

# Generate a new token incase the original expired
TOKEN=$(curl -k -s -X POST "${KEYCLOAK_SERVER_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${KEYCLOAK_ADMIN_USER}" \
  -d "password=${KEYCLOAK_ADMIN_PASSWORD}" \
  -d 'grant_type=password' \
  -d 'client_id=admin-cli' | jq -r '.access_token')

# PW Gen
ADMIN_PASSWORD=$(openssl rand -base64 16)

kubectl create secret generic foundry-admin-secret \
  --from-literal=admin-password="${ADMIN_PASSWORD}" \
  --namespace=foundry

echo "$ADMIN_PASSWORD" > /tmp/foundry_admin_pw.txt 

echo "Creating Admin user"
curl -k -s -X POST "${KEYCLOAK_SERVER_URL}/admin/realms/${REALM_NAME}/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "administrator",
    "email": "administrator@foundry.local",
    "enabled": true,
    "emailVerified": true,
    "firstName": "Foundry",
    "lastName": "Administrator"
  }'

echo "getting admin user id"
ADMIN_ID=$(curl -k -s -X GET "${KEYCLOAK_SERVER_URL}/admin/realms/${REALM_NAME}/users" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')
echo "getting realm client id"
CLIENT_ID=$(curl -k -s -X GET "${KEYCLOAK_SERVER_URL}/admin/realms/${REALM_NAME}/users/$ADMIN_ID/role-mappings/realm" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.[0].id')
echo "getting admin role"
ADMIN_ROLE=$(curl -k -s -X GET "${KEYCLOAK_SERVER_URL}/admin/realms/${REALM_NAME}/roles/admin" \
  -H "Authorization: Bearer $TOKEN")

echo "Assigning 'realm-admin' role to 'administrator'..."
curl -k -s -X POST "${KEYCLOAK_SERVER_URL}/admin/realms/${REALM_NAME}/users/${ADMIN_ID}/role-mappings/realm" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "[${ADMIN_ROLE}]"

# Insert Admin GUID into TopoMojo chart
sed -i -r "s/<ADMIN_ID>/$ADMIN_ID/" topomojo.values.yaml

# Set the password
echo "setting password..."
curl -k -s -X PUT "${KEYCLOAK_SERVER_URL}/admin/realms/${REALM_NAME}/users/${ADMIN_ID}/reset-password" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "password",
    "value": "'"${ADMIN_PASSWORD}"'",
    "temporary": false
  }'

echo "getting new admin token"
# Get new Administrator token for bootstrap user deletion
ADMIN_TOKEN=$(curl -k -s -X POST "https://foundry.local/auth/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-cli" \
  -d "grant_type=password" \
  -d "username=administrator" \
  -d "password=${ADMIN_PASSWORD}" \
  -d "scope=openid" | jq -r '.access_token')
echo "getting foundry user ID"
USER_ID=$(curl -k -s -X GET "https://foundry.local/auth/admin/realms/master/users?username=foundry" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')
echo "delete user"
curl -k -s -X DELETE "https://foundry.local/auth/admin/realms/master/users/${USER_ID}" \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Replace password in start page
sed -i -r "s|<ADMIN_PW>|$ADMIN_PASSWORD|" ../mkdocs/docs/index.md