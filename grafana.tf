resource "random_uuid" "grafana_machine_id" {
}

data "template_cloudinit_config" "grafana_config" {
  gzip          = false # does not work with NoCloud ds?!?
  base64_encode = false # does not work with NoCloud ds?!?

  part {
    content_type = "text/cloud-config"
    content      = <<EOT
#cloud-config

preserve_hostname: false
hostname: ${local.grafana_server.name}
fqdn: ${local.grafana_server.fqdn}
prefer_fqdn_over_hostname: true

ssh_pwauth: True
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: ubuntu
      type: text  

ssh_authorized_keys:
  - "${local.grafana_server.ssh_key}"  

ca_certs:
  trusted:
    - |
      ${indent(6, tls_self_signed_cert.ca_cert.cert_pem)}

EOT
  }

  # part {
  #   content_type = "text/x-shellscript-per-instance"
  #   content = templatefile("${path.module}/cloud-init/consul/setup_consul_server.sh.tpl",
  #     {
  #       deployment_id          = random_uuid.deployment_id.result,
  #       datacenter             = var.datacenter_name,
  #       bootstrap_expect       = length(local.servers),
  #       total_nodes            = length(local.servers),
  #       gossip_key             = random_id.consul_gossip_encryption_key.b64_std,
  #       master_token           = random_uuid.consul_master_token.result,
  #       agent_server_token     = random_uuid.consul_agent_server_token.result,
  #       snapshot_token         = random_uuid.consul_snapshot_token.result,
  #       consul_cluster_version = var.consul_cluster_version,
  #       acl_bootstrap_bool     = var.acl_bootstrap_bool,
  #       retry_join_ips         = [for s in local.servers : s.ip]
  #   })
  # }

  part {
    content_type = "text/x-shellscript-per-instance"
    content      = templatefile("${path.module}/cloud-init/grafana-agent/setup_grafana.sh.tpl", {})
  }

}

resource "libvirt_cloudinit_disk" "grafana_cloudinit" {

  name           = local.grafana_server.cloudinit
  meta_data      = templatefile("${path.module}/cloud-init/meta_data.cfg.tpl", { machine_id = random_uuid.grafana_machine_id.result, hostname = local.grafana_server.name })
  user_data      = data.template_cloudinit_config.grafana_config.rendered
  network_config = templatefile("${path.module}/cloud-init/network_config.cfg.tpl", {})
  pool           = libvirt_pool.monitoring.name
}

resource "libvirt_domain" "grafana_instance" {

  autostart = false
  name      = local.grafana_server.name
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
  cloudinit = libvirt_cloudinit_disk.grafana_cloudinit.id

  network_interface {
    network_id     = libvirt_network.observability_network.id
    hostname       = local.grafana_server.name
    addresses      = [local.grafana_server.ip]
    wait_for_lease = true
  }


  disk {
    volume_id = libvirt_volume.grafana.id
  }

  graphics {
    type = "spice"
  }

  depends_on = [
    libvirt_cloudinit_disk.grafana_cloudinit,
    libvirt_domain.prometheus_instance,
    libvirt_domain.loki_instance,
  ]

  # lifecycle {
  #   create_before_destroy = true
  # }
}

# register prometheus and loki
provider "grafana" {
  url  = "http://${local.grafana_server.ip}:3000/"
  auth = "admin:admin"
}

resource "grafana_data_source" "prometheus" {
  type                = "prometheus"
  name                = "Prometheus"
  url  = "http://${local.prometheus_server.ip}:9090/"
  depends_on = [
    libvirt_domain.grafana_instance
  ]
}

resource "grafana_data_source" "loki" {
  type                = "loki"
  name                = "Loki"
  url  = "http://${local.loki_server.ip}:3100/"
  depends_on = [
    libvirt_domain.grafana_instance
  ]  
}
