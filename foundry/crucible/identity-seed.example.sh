#!/bin/sh -xe
# 
# Copyright 2021 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.

#############################
#   Identity Seed Script    #
#############################

# WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING #
#                                                                                         #
# If you are dependant on the id or globalId of an item use the Identity seed file        #
# In many cases this script will delete and re-create items due to limitation of the      #
# Identity API                                                                            #
#                                                                                         #
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING #    

APP_NAME=${1}
# If JSON files are not in the same directory as the script 
# Specify the directory as the second argument.
DIRECTORY=${2-$(dirname "$BASH_SOURCE[0]")}
cd $DIRECTORY

# http or https
PROTO="https"
DOMAIN="${DOMAIN:-foundry.local}"

# get access token
ACCESS_TOKEN=$(curl --silent --insecure --request POST \
  --url "$PROTO://$DOMAIN/identity/connect/token" \
  --data grant_type=password \
  --data scope="identity-api identity-api-privileged" \
  --data client_id=bootstrap-client \
  --data client_secret=foundry \
  --data username=administrator@foundry.local \
  --data password=foundry | jq -r '.access_token')

# Function exists() 
# Returns ID if the item exists
# returns empty string if it doesn't. 
function exists() {
  TYPE=$1
  NAME=$2

  URL="$PROTO://$DOMAIN/identity/api/${TYPE}s?term=$NAME"
  EXISTS=$(curl --silent --insecure --request GET \
    --url "$URL" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json")
  # RETURN
   echo $(printf '%s' "$EXISTS" | jq '.[0].id // empty')
}

function update() {
  # TYPE can also be used like a path "resource/enlist" without the quotes
  TYPE=$1
  NAME=$2
  ID=$3
  DATA=$4
  
  URL="$PROTO://$DOMAIN/identity/api/${TYPE}"
  

  API_JSON=$(curl --silent --insecure --request GET \
    --url "$URL/$ID" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" | jq '.')
  
  #Combine file and API json
  JSON=$(printf '%s' "$API_JSON $DATA" | jq -sr add)
  UPDATED=$(curl --silent --insecure --request PUT \
  --url "$URL" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON")
  if [[ -n "$UPDATED" ]]; then 
    echo "$NAME Updated" 
  fi
}

function add() {
  TYPE=$1
  NAME=$2
  DATA=$3
  # PROPS is a jq filter string
  # In some cases when creating we need a subset of the json data
  # e.g. '. | {usernames: .usernames, password: .password}'
  PROPS=${4-'.'}
  URL="$PROTO://$DOMAIN/identity/api/${TYPE}"
  
  # Parse JSON for initial POST
    INIT_JSON=$(printf '%s' "$DATA" | jq "$PROPS")
    echo "CREATING NEW $TYPE"
    #Create the resource, get the resource ID and full resource.
    INIT_API=$(curl --silent --insecure --request POST \
    --url "$URL" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$INIT_JSON")
    
    ID=$(printf '%s' "$INIT_API" |jq -r '. | if type=="array" then .[0].id else .id end // empty')
    
    if [[ -n "$ID" ]]; then
      API_JSON=$(curl --silent --insecure --request GET \
      --url "$URL/$ID" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json")

      # Merge JSON
      JSON=$(printf '%s\n%s\n' "$API_JSON" "$DATA" | jq -n '[inputs] | add')
      
      # PUT Update
      ADDED=$(curl --silent --insecure --request PUT \
      --url "$PROTO://$DOMAIN/identity/api/$TYPE" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$JSON" | jq -r '.')
      if [[ -n "$ADDED" ]]; then 
        echo $ADDED
        # Check client scope
        # In some cases the Identity API will create a client successfully but omit scope resources
        # if they don't exists. This can cause authorization to fail, due to invalid scopes. In this 
        # case we assume that if a scope is specified it is required. We fail the script if DATA 
        # scope and ADDED scope do not match so that the init container will restart and try again.
        if [[ "$TYPE" == "client" ]]; then
          DATA_SCOPES=$(printf '%s' "$DATA" | jq -r '.scopes')
          ADD_SCOPES=$(printf '%s' "$ADDED" | jq -r '.scopes')
          if [[ "$DATA_SCOPES" != "$ADD_SCOPES" ]]; then 
            echo "Intended Scopes: $DATA_SCOPES"
            echo "Created Scopes: $ADD_SCOPES\n\n"
            echo "Compare the scopes and make sure the missing scopes application initialized correctly."
            echo "In most cases this is a race condition and a retry is all that is needed.\n"
            echo "Sleeping for 10 seconds before exiting..."
            sleep 10
            exit 1
          fi
        fi
      fi
    fi
}

function delete() {
  TYPE=$1
  NAME=$2
  ID=$3
  URL="$PROTO://$DOMAIN/identity/api/${TYPE}"
  EXISTS=$(curl --silent --insecure --request DELETE \
    --url "$URL/$ID" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json")
  # RETURN
   echo $(printf '%s' "$EXISTS" | jq '.[0].id // empty')
}

# Checks if the file is an array or object 
# Objects will be returned as an array
function isArray() {
  FILE=$1
  RET=$(jq -rc '. | if type!="array" then [.] else . end' "$FILE")
  echo $RET
}

#If Resource JSON exists. Configure Resource
if [[ -e "${DIRECTORY}/$APP_NAME-resource.json" ]]; then
  FILE="${DIRECTORY}/$APP_NAME-resource.json"
  isArray $FILE | jq -c '.[]' | while read object; do
    NAME=$(printf '%s' "$object" | jq -r '.name')
    RESOURCE_ID=$(exists resource $NAME)
    
    if [[ -n "$RESOURCE_ID" ]]; then  
      # Because of some API limitations, delete the resource and add it again
      delete resource $NAME $RESOURCE_ID
      add resource $NAME "$object"
    else
      add resource $NAME "$object"
    fi
  done
fi


#If a client JSON file exists. Configure Client. 
if [[ -e "${DIRECTORY}/$APP_NAME-client.json" ]]; then
  FILE="${DIRECTORY}/$APP_NAME-client.json"
  isArray $FILE | jq -c '.[]' | while read object; do
    NAME=$(printf '%s' "$object" | jq -r '.name')
    CLIENT_ID=$(exists client $NAME)
    
    if [[ -n "$CLIENT_ID" ]]; then  
      # Because of some API limitations, delete the client and add it again
      delete client $NAME $CLIENT_ID
      add client $NAME "$object" '. | {name: .name, displayName: .displayName, description: .description}'
    else
      add client $NAME "$object" '. | {name: .name, displayName: .displayName, description: .description}'
    fi
  done
fi

#If a account JSON file exists. Create Account as long as it doesn't exist. 
if [[ -e "${DIRECTORY}/$APP_NAME-account.json" ]]; then
  FILE="${DIRECTORY}/$APP_NAME-account.json"
  isArray $FILE | jq -c '.[]' | while read object; do
    USERNAME=$(printf '%s' "$object" | jq -r '.usernames[0]')
    ACCOUNT_ID=$(exists account $USERNAME)
    
    if [[ -n "$ACCOUNT_ID" ]]; then  
      # Because of some API limitations, delete the resource and add it again
      echo "Account Exists. Accounts cannot be updated with this script."
    else
      add account $USERNAME "$object" '. | {usernames: .usernames, password: .password}'
    fi
  done
fi
