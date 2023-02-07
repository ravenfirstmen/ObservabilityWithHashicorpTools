#!/usr/bin/env bash

export VAULT_ADDR=https://$(terraform -chdir=.. output -json vault-info | jq -r '[ .[].address ][0]'):8200
export VAULT_CACERT=../certs/ca.pem
export VAULT_TOKEN=$(jq -r '.root_token' unseal-info.json)