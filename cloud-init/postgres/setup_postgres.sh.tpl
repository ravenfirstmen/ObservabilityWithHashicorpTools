#!/usr/bin/env bash

INSTANCE_ID=$(cat /etc/machine-id)
echo "Starting deployment vault on instance: $INSTANCE_ID"
LOCAL_IPV4=$(hostname -I | sed 's/[[:space:]]//g') 
NODE_NAME=$(hostname -s) 

sudo -u postgres psql <<'EOF'
CREATE DATABASE vault;
CREATE USER vault WITH PASSWORD '${pg_passwd}';
GRANT ALL PRIVILEGES ON DATABASE vault to vault
EOF

PGPASSWORD=${pg_passwd} psql -U vault -d vault <<'EOF'
CREATE TABLE vault_kv_store (
  parent_path TEXT COLLATE "C" NOT NULL,
  path        TEXT COLLATE "C",
  key         TEXT COLLATE "C",
  value       BYTEA,
  CONSTRAINT pkey PRIMARY KEY (path, key)
);

CREATE INDEX parent_path_idx ON vault_kv_store (parent_path);

CREATE TABLE vault_ha_locks (
  ha_key                                      TEXT COLLATE "C" NOT NULL,
  ha_identity                                 TEXT COLLATE "C" NOT NULL,
  ha_value                                    TEXT COLLATE "C",
  valid_until                                 TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT ha_key PRIMARY KEY (ha_key)
);
EOF