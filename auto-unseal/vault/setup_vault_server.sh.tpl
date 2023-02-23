#!/usr/bin/env bash

INSTANCE_ID=$(cat /etc/machine-id)
echo "Starting deployment vault on instance: $INSTANCE_ID"
LOCAL_IPV4=$(hostname -I | sed 's/[[:space:]]//g') 
NODE_NAME=$(hostname -s) 

# removing any default installation files from /opt/vault/tls/
rm -rf /opt/vault/tls/*

# /opt/vault/tls should be readable by all users of the system
chmod 0755 /opt/vault/tls

# vault-key.pem should be readable by the vault group only
touch /opt/vault/tls/vault-key.pem
chown root:vault /opt/vault/tls/vault-key.pem
chmod 0640 /opt/vault/tls/vault-key.pem

VAULT_CERTIFICATES_DATA=$(echo "${vault_certificates_data}" | base64 --decode)

jq -r .vault_cert <<< "$VAULT_CERTIFICATES_DATA" | base64 -d > /opt/vault/tls/vault-cert.pem
jq -r .vault_ca <<< "$VAULT_CERTIFICATES_DATA" | base64 -d > /opt/vault/tls/vault-ca.pem
jq -r .vault_pk <<< "$VAULT_CERTIFICATES_DATA" | base64 -d > /opt/vault/tls/vault-key.pem


cat << EOF > /etc/vault.d/vault.hcl
ui = true
disable_mlock = true

cluster_addr = "https://$LOCAL_IPV4:8201"
api_addr = "https://$LOCAL_IPV4:8200"

storage "consul" {
  token = "${vault_storage_backend_token}"
  path = "${vault_consul_kv_path}/"
  address = "${consul_cluster_end_point}"
  scheme = "https"
  service = "vault"
  service_tags ="vault,vault-01"   
  tls_key_file = "/opt/vault/tls/vault-key.pem"
  tls_cert_file = "/opt/vault/tls/vault-cert.pem"
  tls_ca_file = "/opt/vault/tls/vault-ca.pem"
  tls_min_version = "tls12"
  tls_skip_verify = "false"
}

listener "tcp" {
  address            = "0.0.0.0:8200"
  tls_disable        = false
  tls_cert_file      = "/opt/vault/tls/vault-cert.pem"
  tls_key_file       = "/opt/vault/tls/vault-key.pem"
  tls_client_ca_file = "/opt/vault/tls/vault-ca.pem"
  telemetry {
    unauthenticated_metrics_access = true
  }
}

telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}

seal "transit" {
  address            = "https://${vault_cluster_end_point}:8200"
  token              = "${vault_autounseal_token}"
  disable_renewal    = "false"

  // Key configuration
  key_name           = "${vault_transit_key_name}"
  mount_path         = "${vault_transit_mount_point}"

  // TLS Configuration
  tls_ca_cert        = "/opt/vault/tls/vault-ca.pem"
  tls_client_cert    = "/opt/vault/tls/vault-cert.pem"
  tls_client_key     = "/opt/vault/tls/vault-key.pem"
  tls_skip_verify    = "true"
}

EOF

chown root:root /etc/vault.d
chown root:vault /etc/vault.d/vault.hcl
chmod 640 /etc/vault.d/vault.hcl

systemctl enable vault
systemctl start vault

echo "Setup Vault profile" # apenas um helper
cat <<PROFILE | sudo tee /etc/profile.d/vault.sh
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_CACERT="/opt/vault/tls/vault-ca.pem"
PROFILE

%{~ if run_init_process ~}

export VAULT_ADDR="https://127.0.0.1:8200"

VAULT_INITIALIZED=$(curl -s $VAULT_ADDR/v1/sys/init | jq -r '.initialized')
echo $VAULT_INITIALIZED
if [ "$VAULT_INITIALIZED" = "false" ];
then
  echo "I'm NOT initialized!!!"
  echo "Starting unseal..."
  UNSEAL_INFO=$(curl -s --request POST $VAULT_ADDR/v1/sys/init --data '{ "stored_shares": 5, "recovery_shares": 5, "recovery_threshold": 3 }')
  echo $UNSEAL_INFO > unseal-info.json
  # VAULT_TOKEN=$(echo $UNSEAL_INFO | jq -r '.root_token')
  # echo "Revoking $VAULT_TOKEN ..."
  # curl -s --header "X-Vault-Token: $VAULT_TOKEN" --request POST $VAULT_ADDR/v1/auth/token/revoke-self
  # echo "Done revoking $VAULT_TOKEN ..."
else 
  echo "I'm initialized!!!"
fi

%{~ endif ~}