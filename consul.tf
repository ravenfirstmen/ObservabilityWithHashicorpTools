# consul secrets
resource "random_uuid" "consul_master_token" {}
resource "random_uuid" "consul_agent_server_token" {}
resource "random_uuid" "consul_snapshot_token" {}
resource "random_id" "consul_gossip_encryption_key" {
  byte_length = 32
}
# end consul secrets

resource "random_uuid" "deployment_id" {
  # keepers = {
  #   instance_id = md5(join("", [for c in libvirt_domain.consul-instance : c.id]))
  # }
}

resource "random_uuid" "consul_machine_id" {
  for_each = local.consul_servers
}

data "template_cloudinit_config" "consul_config" {
  for_each = local.consul_servers

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
    content: ${base64encode(templatefile("${path.module}/cloud-init/grafana-agent/grafana-agent-consul-service-registration.hcl.tpl", { agent_server_token = random_uuid.consul_agent_server_token.result }))}
    path: /etc/consul.d/grafana-agent-service-registration.hcl
  - encoding: b64
    content: ${base64encode(templatefile("${path.module}/cloud-init/grafana-agent/grafana-agent-for-consul.yaml", { role = "consul", prometheus_endpoint = local.prometheus_server.ip, consul_token = random_uuid.consul_agent_server_token.result, loki_endpoint = local.loki_server.ip }))}
    path: /etc/grafana-agent.yaml
EOT
  }

  part {
    content_type = "text/x-shellscript-per-instance"
    content = templatefile("${path.module}/cloud-init/consul/setup_consul_server.sh.tpl",
      {
        deployment_id          = random_uuid.deployment_id.result,
        datacenter             = var.datacenter_name,
        bootstrap_expect       = length(local.consul_servers),
        total_nodes            = length(local.consul_servers),
        gossip_key             = random_id.consul_gossip_encryption_key.b64_std,
        master_token           = random_uuid.consul_master_token.result,
        agent_server_token     = random_uuid.consul_agent_server_token.result,
        snapshot_token         = random_uuid.consul_snapshot_token.result,
        consul_cluster_version = var.consul_cluster_version,
        acl_bootstrap_bool     = var.acl_bootstrap_bool,
        retry_join_ips         = [for s in local.consul_servers : s.ip]
    })
  }

  part {
    content_type = "text/x-shellscript-per-instance"
    content      = templatefile("${path.module}/cloud-init/grafana-agent/setup_grafana.sh.tpl", {})
  }

}

resource "libvirt_cloudinit_disk" "consul_cloudinit" {
  for_each = local.consul_servers

  name           = each.value.cloudinit
  meta_data      = templatefile("${path.module}/cloud-init/meta_data.cfg.tpl", { machine_id = random_uuid.consul_machine_id[each.key].result, hostname = each.value.name })
  user_data      = data.template_cloudinit_config.consul_config[each.key].rendered
  network_config = templatefile("${path.module}/cloud-init/network_config.cfg.tpl", {})
  pool           = libvirt_pool.hashicorp.name
}

resource "libvirt_domain" "consul-instance" {
  for_each = local.consul_servers

  autostart = false
  name      = each.value.name
  memory    = "2048"
  vcpu      = 1
  machine   = "q35"
  xml { # para a q35 o cdrom necessita de ser sata
    xslt = file("lib-virt/q35-cdrom-model.xslt")
  }
  qemu_agent = true

  cpu {
    mode = "host-passthrough"
  }

  firmware  = "${local.uefi_location_files}/OVMF_CODE.fd"
  cloudinit = libvirt_cloudinit_disk.consul_cloudinit[each.key].id

  network_interface {
    network_id     = libvirt_network.observability_network.id
    hostname       = each.value.name
    addresses      = [each.value.ip]
    wait_for_lease = true
  }


  disk {
    volume_id = libvirt_volume.consul[each.key].id
  }

  graphics {
    type = "spice"
  }

  depends_on = [
    libvirt_cloudinit_disk.consul_cloudinit
  ]

  # lifecycle {
  #   create_before_destroy = true
  # }
}

