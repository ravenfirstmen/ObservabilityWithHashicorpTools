#cloud-config

preserve_hostname: false
hostname: ${hostname}
fqdn: ${host_fqdn}
prefer_fqdn_over_hostname: true

ssh_pwauth: True
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: ubuntu
      type: text  

ssh_authorized_keys:
  - "${public_ssh_key}"    
