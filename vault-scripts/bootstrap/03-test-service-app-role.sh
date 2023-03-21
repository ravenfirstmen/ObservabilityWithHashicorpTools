#!/bin/bash

vault_servers=($(terraform -chdir=../.. output -json vault-info | jq -r '.[].address'))
first_vault_server=${vault_servers[0]}

export VAULT_ADDR=https://${first_vault_server}:8200
export VAULT_CACERT=../../certs/ca.pem

APP_ROLE_ID="..."
APP_SECRET_ID="..."
APP_ROLE_PATH="services-approle"
SERVICE_NAME="antonio"

# test
vault write auth/$APP_ROLE_PATH/login role_id=$APP_ROLE_ID secret_id=$APP_SECRET_ID