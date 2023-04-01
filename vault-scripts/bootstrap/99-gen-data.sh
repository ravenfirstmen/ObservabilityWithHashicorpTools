#!/usr/bin/env bash

UNSEAL_INFO_FILE="../unseal-info.json"

if [ ! -f $UNSEAL_INFO_FILE ];
then
    echo "No $UNSEAL_INFO_FILE file found. Most likely the vault was not initialized and unsealed....!"
    exit 1
fi


vault_servers=($(terraform -chdir=../.. output -json vault-info | jq -r '.[].address'))
first_vault_server=${vault_servers[0]}

export VAULT_ADDR=https://${first_vault_server}:8200
export VAULT_CACERT=../../certs/ca.pem
VAULT_ROOT_TOKEN=$(cat $UNSEAL_INFO_FILE | jq -r '.root_token')


SERVICES_APP_ROLE_PATH=services-approle
SERVICES_USERNAME_PATH=services-userpass

iterations=0

while [ $iterations -le 30 ]
do

  for user in antonio salgado
  do
    app_role_id=$(terraform output -raw ${user}_approle_role_id)
    app_secret_id=$(terraform output -raw ${user}_approle_secret_id)
    # login with app role
    vault write auth/$SERVICES_APP_ROLE_PATH/login role_id=$app_role_id secret_id=$app_secret_id

    #sleep 0.5

    userpass_password=$(terraform output -raw ${user}_userpass_password)
    userpass_username=$(terraform output -raw ${user}_userpass_username)
    # login with username
    vault write auth/$SERVICES_APP_ROLE_PATH/login role_id=$app_role_id secret_id=$app_secret_id
    vault login -no-store -method=userpass -path=$SERVICES_USERNAME_PATH username=$userpass_username password=$userpass_password

    #sleep 0.5

    vault login -token-only -wrap-ttl="30s" -method=cert -path=services-cert -client-cert=$user.pem  -client-key=$user-key.der  name=$user
    vault login -token-only -wrap-ttl="30s" -method=userpass -path=$SERVICES_USERNAME_PATH -client-cert=$user.pem  username=$userpass_username password=$userpass_password

  done

  nkvs=0
  while [ $nkvs -le 30 ]
  do
    uid_key=$(uuidgen -rt)
    uid_val=$(uuidgen -rt)
    VAULT_TOKEN=$VAULT_ROOT_TOKEN vault kv put kv/${uid_key} value="${uid_val}"
    VAULT_TOKEN=$VAULT_ROOT_TOKEN vault write pki/issue/client_certificates common_name=www.${uid_val}.com
    #VAULT_TOKEN=$VAULT_ROOT_TOKEN vault read pki/issue/client_certificates
    VAULT_TOKEN=$VAULT_ROOT_TOKEN vault write transit/encrypt/enc-key plaintext=$(uuidgen -rt | base64)
    nkvs=$(( $nkvs + 1 ))
  done

  iterations=$(( $iterations + 1 ))
done
