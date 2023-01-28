
resource "random_uuid" "vault_machine_id" {
  for_each = local.vault_servers
}

data "template_cloudinit_config" "vault_config" {
  for_each = local.vault_servers

  gzip          = false # does not work with NoCloud ds?!?
  base64_encode = false # does not work with NoCloud ds?!?

  part {
    content_type = "text/cloud-config"
    content      = <<EOT
#cloud-config

preserve_hostname: false
hostname: ${each.value.name}
fqdn: ${each.value.fqdn}
prefer_fqdn_over_hostname: true

ssh_pwauth: True
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: ubuntu
      type: text  

ssh_authorized_keys:
  - "${each.value.ssh_key}"  

ca_certs:
  trusted:
    - |
      ${indent(6, tls_self_signed_cert.ca_cert.cert_pem)}

write_files:
  - encoding: b64
    content: ${base64encode(tls_self_signed_cert.ca_cert.cert_pem)}
    path: /etc/consul.d/certs/ca.pem
  - encoding: b64
    content: ${base64encode(tls_private_key.ca_key.private_key_pem)}
    path: /tmp/ca-key.pem
  - encoding: b64
    content: ${base64encode(templatefile("${path.module}/cloud-init/grafana-agent/grafana-agent-for-vault.yaml", { role = "vault", prometheus_endpoint = local.prometheus_server.ip, loki_endpoint = local.loki_server.ip }))}
    path: /etc/grafana-agent.yaml
  - encoding: b64
    content: ${base64encode(file("${path.module}/cloud-init/vault/unseal.sh"))}
    path: /home/ubuntu/unseal.sh
    owner: ubuntu:ubuntu
    permissions: '0700'    
EOT
  }

  part {
    content_type = "text/x-shellscript-per-instance"
    content = templatefile("${path.module}/cloud-init/vault/setup_vault_server.sh.tpl",
      {
        leader_tls_servername = local.vault_domain
        node_name  = each.value.name
        current_node_ip = each.value.ip
        retry_join_ips         = [for s in local.vault_servers : s.ip]
        vault_certificates_data = local.vault_certificates
    })
  }

  part {
    content_type = "text/x-shellscript-per-instance"
    content      = templatefile("${path.module}/cloud-init/grafana-agent/setup_grafana-for-vault.sh.tpl", { machine_ip = each.value.ip, ca_certificate = local.ca_certificate })
  }

}

resource "libvirt_cloudinit_disk" "vault_cloudinit" {
  for_each = local.vault_servers

  name           = each.value.cloudinit
  meta_data      = templatefile("${path.module}/cloud-init/meta_data.cfg.tpl", { machine_id = random_uuid.vault_machine_id[each.key].result, hostname = each.value.name })
  user_data      = data.template_cloudinit_config.vault_config[each.key].rendered
  network_config = templatefile("${path.module}/cloud-init/network_config.cfg.tpl", {})
  pool           = libvirt_pool.hashicorp.name
}

resource "libvirt_domain" "vault-instance" {
  for_each = local.vault_servers

  autostart = false
  name      = each.value.name
  memory    = "4096"
  vcpu      = 2
  machine   = "q35"
  xml { # para a q35 o cdrom necessita de ser sata
    xslt = file("lib-virt/q35-cdrom-model.xslt")
  }
  qemu_agent = true

  cpu {
    mode = "host-passthrough"
  }

  firmware  = "${local.uefi_location_files}/OVMF_CODE.fd"
  cloudinit = libvirt_cloudinit_disk.vault_cloudinit[each.key].id

  network_interface {
    network_id     = libvirt_network.observability_network.id
    hostname       = each.value.name
    addresses      = [each.value.ip]
    wait_for_lease = true
  }


  disk {
    volume_id = libvirt_volume.vault[each.key].id
  }

  graphics {
    type = "spice"
  }

  depends_on = [
    libvirt_cloudinit_disk.vault_cloudinit
  ]

  # lifecycle {
  #   create_before_destroy = true
  # }
}

