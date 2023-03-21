#!/bin/bash

APPROLE_INFO_FILE="./app-role-info.json"

if [ ! -f $APPROLE_INFO_FILE ];
then
    echo "No $APPROLE_INFO_FILE file found. Most likely the god app role was not created....!"
    exit 1
fi

APPROLE_INFO=$(cat $APPROLE_INFO_FILE)
login_approle_role_id=$(echo $APPROLE_INFO | jq -r '.role_id')
login_approle_secret_id=$(echo $APPROLE_INFO | jq -r '.secret_id')
login_approle_path=$(echo $APPROLE_INFO | jq -r '.path')

cat > terraform.tfvars <<EOF
login_approle_role_id="$login_approle_role_id"
login_approle_secret_id="$login_approle_secret_id"
login_approle_path="$login_approle_path"
EOF

# test
#vault write auth/$login_approle_path/login role_id=$login_approle_role_id secret_id=$login_approle_secret_id
