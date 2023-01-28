#!/usr/bin/env bash

INSTANCE_ID=$(cat /etc/machine-id)
echo "Starting deployment consul on instance: $INSTANCE_ID"
LOCAL_IPV4=$(hostname -I | sed 's/[[:space:]]//g') 
NODE_NAME=$(hostname -s) 

# generate the certificates
mkdir -p /etc/consul.d/certs
consul tls cert create -ca=/etc/consul.d/certs/ca.pem -dc=${datacenter} -key=/tmp/ca-key.pem -server -node=$NODE_NAME -additional-ipaddress=$LOCAL_IPV4 -additional-dnsname=$(hostname --long)
mv ${datacenter}-server-consul-0-key.pem /etc/consul.d/certs/cert-key.pem
mv ${datacenter}-server-consul-0.pem /etc/consul.d/certs/cert.pem
rm -rf /tmp/ca-key.pem
# done certificates

cat << EOF > /etc/consul.d/log.hcl
log_file = "/var/log/consul/"
log_level = "DEBUG"
log_rotate_duration = "24h"
log_rotate_max_files = 7
EOF

cat << EOF > /etc/consul.d/ui.hcl
ui_config {
  enabled = true
}
EOF

cat << EOF > /etc/consul.d/gossip.hcl
encrypt = "${gossip_key}"
EOF

cat << EOF > /etc/consul.d/acl.hcl
acl {
  enabled        = true
  %{ if acl_bootstrap_bool }default_policy = "allow"%{ else }default_policy = "deny"%{ endif }
  down_policy = "extend-cache"
  enable_token_persistence = true
  tokens {
    initial_management = "${master_token}"
    %{ if !acl_bootstrap_bool }
    agent  = "${agent_server_token}"
    %{ endif }
  }
}

%{ if !acl_bootstrap_bool }
service {
	name = "backend"
	port = 8500
  	tags = ["backend"]
  	token = "${agent_server_token}"
}
%{ endif }
EOF

cat << EOF > /etc/consul.d/ports.hcl
ports  {
  dns = -1
  http = 8500
  https = 8501
  server = 8300
  serf_lan = 8301
}
EOF


cat << EOF > /etc/consul.d/telemetry.hcl
telemetry {
  prefix_filter = ["-consul.catalog.connect", "-consul.dns"]
  prometheus_retention_time = "1h"
  disable_hostname = true # do not prefix metrics with hostname
}
EOF

cat << EOF > /etc/consul.d/tls.hcl
tls {
  defaults {
    ca_file = "/etc/consul.d/certs/ca.pem"
    cert_file = "/etc/consul.d/certs/cert.pem"
    key_file = "/etc/consul.d/certs/cert-key.pem"
    tls_min_version = "TLSv1_2"
    verify_incoming = true
    verify_outgoing = true
  }

  internal_rpc {
    verify_server_hostname = true
  }
}
auto_encrypt {
  allow_tls = true
}
EOF

cat << EOF > /etc/consul.d/consul.hcl
server = true
node_name = "$NODE_NAME"
server_name = "$NODE_NAME.server.${datacenter}.consul"
datacenter = "${datacenter}"
bootstrap_expect = ${bootstrap_expect}
advertise_addr      = "$LOCAL_IPV4"
client_addr         = "0.0.0.0"

retry_join = ["${ join("\",\"", retry_join_ips) }"]

leave_on_terminate = true
reconnect_timeout = "8h"
reconnect_timeout_wan = "8h"

data_dir = "/consuldata"

performance {
    raft_multiplier = 1 # it's on my local machine....
}

EOF


cat << EOF > /etc/consul.d/cluster_version.hcl
node_meta = {
    deployment_id = "${deployment_id}"
}
EOF

%{ if acl_bootstrap_bool }
cat << EOF > /tmp/bootstrap_tokens.sh
#!/bin/bash
export CONSUL_HTTP_TOKEN=${master_token}
echo "Creating Consul ACL policies......"
if ! consul kv get acl_bootstrap 2>/dev/null; then
  consul kv put  acl_bootstrap 1

  echo '
  consul_node_prefix "" {
    policy = "write"
  }
  service_prefix "" {
    policy = "read"
  }
  service "consul" {
    policy = "write"
  }
  service "grafana-agent" {
    policy = "write"
  }  
  agent_prefix "" {
    policy = "write"
  }' | consul acl policy create -name consul-agent-server -rules -

  # echo '
  # acl = "write"
  # key "consul-snapshot/lock" {
  # policy = "write"
  # }
  # session_prefix "" {
  # policy = "write"
  # }
  # service "consul-snapshot" {
  # policy = "write"
  # }' | consul acl policy create -name snapshot_agent -rules -

  echo '
  consul_node_prefix "" {
    policy = "read"
  }
  service_prefix "" {
    policy = "read"
  }
  session_prefix "" {
    policy = "read"
  }
  agent_prefix "" {
    policy = "read"
  }
  query_prefix "" {
    policy = "read"
  }
  operator = "read"' |  consul acl policy create -name anonymous -rules -

  consul acl token create -description "consul agent server token" -policy-name consul-agent-server -secret "${agent_server_token}" 1>/dev/null
  # consul acl token create -description "consul snapshot agent" -policy-name snapshot_agent -secret "${snapshot_token}" 1>/dev/null
  consul acl token update -id anonymous -policy-name anonymous 1>/dev/null
else
  echo "Bootstrap already completed"
fi
EOF

chmod 700 /tmp/bootstrap_tokens.sh

%{ endif }


chown -R consul:consul /etc/consul.d
chmod -R u+rw,g+r,go-wx,o-r /etc/consul.d/*
chmod -R u+x /etc/consul.d/certs

systemctl daemon-reload
systemctl enable consul
systemctl start consul

# Wait for consul-kv to come online
while true; do
    curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -e . && break
    sleep 5
done

# Wait until all new node versions are online
until [[ $TOTAL_NEW -ge ${total_nodes} ]]; do
    TOTAL_NEW=`curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -er 'map(select(.NodeMeta.deployment_id == "${deployment_id}")) | length'`
    sleep 5
    echo "Current New Node Count: $TOTAL_NEW"
done

# Wait for a leader
until [[ $LEADER -eq 1 ]]; do
    let LEADER=0
    echo "Fetching new node ID's"
    NEW_NODE_IDS=`curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -r 'map(select(.NodeMeta.deployment_id == "${deployment_id}")) | .[].ID'`
    # Wait until all new nodes are voting
    until [[ $VOTERS -eq ${bootstrap_expect} ]]; do
        let VOTERS=0
        for ID in $NEW_NODE_IDS; do
            echo "Checking $ID"
            curl -s http://127.0.0.1:8500/v1/operator/autopilot/health | jq -e ".Servers[] | select(.ID == \"$ID\" and .Voter == true)" && let "VOTERS+=1" && echo "Current Voters: $VOTERS"
            sleep 2
        done
    done
    echo "Checking Old Nodes"
    OLD_NODES=`curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -er 'map(select(.NodeMeta.deployment_id != "${deployment_id}")) | length'`
    echo "Current Old Node Count: $OLD_NODES"
    # Wait for old nodes to drop from voting
    until [[ $OLD_NODES -eq 0 ]]; do
        OLD_NODES=`curl -s http://127.0.0.1:8500/v1/catalog/service/curl -s http://127.0.0.1:8500/v1/catalog/service/consulonsul | jq -er 'map(select(.NodeMeta.deployment_id != "${deployment_id}")) | length'`
        OLD_NODE_IDS=`curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -r 'map(select(.NodeMeta.deployment_id != "${deployment_id}")) | .[].ID'`
        for ID in $OLD_NODE_IDS; do
            echo "Checking Old $ID"
            curl -s http://127.0.0.1:8500/v1/operator/autopilot/health | jq -e ".Servers[] | select(.ID == \"$ID\" and .Voter == false)" && let "OLD_NODES-=1" && echo "Checking Old Nodes for Voters: $OLD_NODES"
            sleep 2
        done
    done
    # Check if there is a leader running the newest version
    LEADER_ID=`curl -s http://127.0.0.1:8500/v1/operator/autopilot/health | jq -er ".Servers[] | select(.Leader == true) | .ID"`
    curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -er ".[] | select(.ID == \"$LEADER_ID\" and .NodeMeta.deployment_id == \"${deployment_id}\")" && let "LEADER+=1" && echo "New Leader: $LEADER_ID"
    sleep 2
done

%{ if acl_bootstrap_bool }/tmp/bootstrap_tokens.sh%{ endif }
echo "$INSTANCE_ID determined all nodes to be healthy and ready to go <3"