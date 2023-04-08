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

%{~ if is_consul_backend_storage ~}

storage "consul" {
  token = "${vault_storage_backend_token}"
  path = "${vault_kv_path}/"
  address = "${consul_cluster_end_point}"
  scheme = "https"
  service = "vault"
  service_tags ="vault,${vault_kv_path}"   
  tls_key_file = "/opt/vault/tls/vault-key.pem"
  tls_cert_file = "/opt/vault/tls/vault-cert.pem"
  tls_ca_file = "/opt/vault/tls/vault-ca.pem"
  tls_min_version = "tls12"
  tls_skip_verify = "false"
}

%{~ endif ~}

%{~ if is_integrated_storage ~}

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "${node_name}"
  
  %{~ for ip in retry_join_ips ~}
  %{~ if ip != current_node_ip ~}
  retry_join {
    leader_api_addr = "https://${ip}:8200"
    leader_tls_servername = "${leader_tls_servername}"
    leader_ca_cert_file = "/opt/vault/tls/vault-ca.pem"
    leader_client_cert_file = "/opt/vault/tls/vault-cert.pem"
    leader_client_key_file = "/opt/vault/tls/vault-key.pem"
  }
  %{~ endif ~}
  %{~ endfor ~}
}
%{~ endif ~}

%{~ if is_postgres_storage ~}

storage "postgresql" {
  connection_url = "postgres://vault:${pg_password}@${pg_server}/vault?sslmode=prefer"
  ha_enabled = "true"
  table = "vault_kv_store"
  ha_table = "vault_ha_locks"
}

%{~ endif ~}

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
