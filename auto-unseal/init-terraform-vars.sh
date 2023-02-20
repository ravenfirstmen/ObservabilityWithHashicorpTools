#!/usr/bin/env bash

TERRAFORM_TF_VARS_FILE="terraform.tfvars"
VAULT_UNSEAL_INFO_FILE="../vault-scripts/vault-cluster-auto-unseal-token.json"

if [ ! -f $VAULT_UNSEAL_INFO_FILE ];
then
    echo "No $VAULT_UNSEAL_INFO_FILE file found. Most likely the primary vault was not prepared....!"
    exit 1
fi

cp terraform.tfvars.ref $TERRAFORM_TF_VARS_FILE

cat <<EOF >> $TERRAFORM_TF_VARS_FILE
prometheus_endpoint = "$(terraform -chdir=.. output -json prometheus-info | jq -r '.address')"
loki_endpoint = "$(terraform -chdir=.. output -json loki-info | jq -r '.address')"

consul_cluster_end_point = "$(terraform -chdir=.. output -json consul-info | jq -r '."consul-node-0".address')" 
consul_management_token = "$(terraform -chdir=.. output -raw consul_master_token)"
consul_datacenter_name = "consul-dc1"

vault_cluster_end_point = "$(terraform -chdir=.. output -json vault-info | jq -r '."vault-node-0".address')" 
vault_autounseal_token = "$(cat ../vault-scripts/vault-cluster-auto-unseal-token.json | jq -r '.auth.client_token')"
vault_transit_key_name = "vault-cluster-auto-unseal"
vault_transit_mount_point = "transit/"

network_name = "$(terraform -chdir=.. output -raw network_name)"
network_domain = "$(terraform -chdir=.. output -raw network_domain)"
network_cidr = "$(terraform -chdir=.. output -raw network_cidr)"

EOF
