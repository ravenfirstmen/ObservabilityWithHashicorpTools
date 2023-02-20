#!/usr/bin/env bash

UNSEAL_INFO_FILE="unseal-info.json"

if [ ! -f $UNSEAL_INFO_FILE ];
then
    echo "No $UNSEAL_INFO_FILE file found. Most likely the vault was not initialized and unsealed....!"
    exit 1
fi

vault_servers=($(terraform -chdir=.. output -json vault-info | jq -r '.[].address'))
first_vault_server=${vault_servers[0]}

export VAULT_ADDR="https://$first_vault_server:8200"
export VAULT_CACERT="../certs/ca.pem"
export VAULT_TOKEN=$(cat $UNSEAL_INFO_FILE | jq -r '.root_token')

vault secrets enable transit

vault write -force transit/keys/vault-cluster-auto-unseal

vault policy write vault-cluster-auto-unseal - <<EOF 
path "transit/encrypt/vault-cluster-auto-unseal" {
   capabilities = [ "update" ]
}

path "transit/decrypt/vault-cluster-auto-unseal" {
   capabilities = [ "update" ]
}
EOF

vault token create -orphan -policy="vault-cluster-auto-unseal" -format=json > "vault-cluster-auto-unseal-token.json"
