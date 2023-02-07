#!/usr/bin/env bash

source ./env.sh

cat <<'EOF' | vault policy write Audit -
path "sys/audit/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "sys/audit"
{
  capabilities = ["read", "sudo"]
}
EOF

vault audit enable file file_path=/var/log/vault/vault-audit.log  