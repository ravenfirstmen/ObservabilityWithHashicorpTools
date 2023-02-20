#!/bin/bash

export VAULT_ADDR=https://localhost:8200
export VAULT_CACERT=/opt/vault/tls/vault-ca.pem

UNSEAL_INFO_FILE="unseal-info.json"

function unseal_vault {

  local unseal_info
	
  if [ ! -f $UNSEAL_INFO_FILE ];
  then
    vault operator init -format=json > $UNSEAL_INFO_FILE
  fi
  
  # unseal_info=$(cat $UNSEAL_INFO_FILE)
  # unseal_threshold=$(echo $unseal_info | jq -r '.unseal_threshold')
  
  # echo $unseal_info | jq -r '.unseal_keys_b64[]' | head -n $unseal_threshold | while read key;
  # do 
  #   vault operator unseal $key
  # done

  echo "Vault unsealed.... the unseal info IS in $UNSEAL_INFO_FILE file"  
} 

vault status 1>/dev/null
case $? in

  "0")
    echo "Already unsealed! move on... BTW: the unseal info SHOULD be in $UNSEAL_INFO_FILE file"
    ;;

  "1")
    echo "Some error in the vault instance... exiting unseal process!"
    exit 1
    ;;

  "2")
    unseal_vault
    ;;

  *)
    echo "What?! (response was: $?)"
    ;;
esac