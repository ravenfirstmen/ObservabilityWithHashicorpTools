#!/usr/bin/env bash

UNSEAL_INFO="unseal-info.json"

vault_servers=($(terraform -chdir=.. output -json vault-info | jq -r '.[].address'))
first_vault_server=${vault_servers[0]}
other_vault_servers=("${vault_servers[@]/$first_vault_server}") # delete the first from the array

# unseal the first and get the unseal_info
echo "Unsealing server $first_vault_server ..."
ssh -i ../ssh-nodes-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$first_vault_server './unseal.sh'
scp -i ../ssh-nodes-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$first_vault_server:$UNSEAL_INFO .

echo "Wait 2s for raft replication ..."
sleep 2s

# unseal the others
for server in ${other_vault_servers[@]};
do
    echo "Unsealing server $server ..."
    scp -i ../ssh-nodes-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" $UNSEAL_INFO ubuntu@$server:$UNSEAL_INFO
    ssh -i ../ssh-nodes-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$server './unseal.sh'
done