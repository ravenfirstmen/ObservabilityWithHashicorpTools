#!/bin/bash

vault_servers=($(terraform -chdir=../.. output -json vault-info | jq -r '.[].address'))
first_vault_server=${vault_servers[0]}

UNSEAL_INFO_FILE="../unseal-info.json"

if [ ! -f $UNSEAL_INFO_FILE ];
then
    echo "No $UNSEAL_INFO_FILE file found. Most likely the vault was not initialized and unsealed....!"
    exit 1
fi

export VAULT_ADDR=https://${first_vault_server}:8200
export VAULT_CACERT=../certs/ca.pem
export VAULT_TOKEN=$(cat $UNSEAL_INFO_FILE | jq -r '.root_token')

APP_ROLE_NAME="approle"
APP_ROLE_ROLE_NAME="admin"
APP_ROLE_POLICY_NAME="vault-$APP_ROLE_NAME-policy"

vault policy read $APP_ROLE_POLICY_NAME >/dev/null

if [ $? -ne 0 ];
then
vault policy write $APP_ROLE_POLICY_NAME - <<EOF 
path "*" {
   capabilities = [ "sudo", "create", "read", "update", "delete", "patch" ]
}
EOF

vault auth enable -path=$APP_ROLE_NAME approle 
vault write auth/$APP_ROLE_NAME/role/$APP_ROLE_ROLE_NAME policies=$APP_ROLE_POLICY_NAME
fi

role_id=$(vault read auth/$APP_ROLE_NAME/role/$APP_ROLE_ROLE_NAME/role-id -format=json | jq -r '.data.role_id')
secret_id=$(vault write -f auth/$APP_ROLE_NAME/role/$APP_ROLE_ROLE_NAME/secret-id -format=json | jq -r '.data.secret_id')

# test
#vault write auth/$APP_ROLE_NAME/login role_id=$role_id secret_id=$secret_id

cat > app-role-info.json <<EOF
{
    "path": "$APP_ROLE_NAME",
    "role_id": "$role_id",
    "secret_id": "$secret_id"
}
EOF

cat > provider-config.tf <<EOF
provider "vault" {
  address               = "${VAULT_ADDR}"
  skip_tls_verify       = true
  max_lease_ttl_seconds = 600
  auth_login {
    path   = "auth/${var.login_approle_path}/login"
    method = "approle"

    parameters = {
      role_id   = var.login_approle_role_id
      secret_id = var.login_approle_secret_id
    }
  }
}
EOF