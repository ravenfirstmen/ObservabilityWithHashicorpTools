#!/bin/bash

TF_PROVISIONED_DOMAINS=$(terraform output -json node-names | jq -r '.[]')

for domain in ${TF_PROVISIONED_DOMAINS} ; do
    if [[ $(virsh --connect qemu:///system list | grep $domain | grep 'running$') ]] ; then
        virsh --connect qemu:///system shutdown "$domain"
    fi

done