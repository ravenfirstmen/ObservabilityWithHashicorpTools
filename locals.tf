locals {
  uefi_location_files = "/usr/share/OVMF"
  #nvram_location = "/var/lib/libvirt/qemu/nvram"
}

# https://github.com/dmacvicar/terraform-provider-libvirt/issues/778

locals {
  consul_servers = {
    for n in range(var.n_consul_nodes) : "${var.consul_node_prefix}-${n}" => {
      name      = "${var.consul_node_prefix}-${n}"
      fqdn      = "${var.consul_node_prefix}-${n}.${var.network_domain}"
      ip        = "${cidrhost(var.network_cidr, n + 10)}"
      volume    = "${var.consul_node_prefix}-${n}.qcow2"
      cloudinit = "${var.consul_node_prefix}-${n}-cloudinit.iso"
      ssh_key   = tls_private_key.ssh.public_key_openssh
      index     = n
    }
  }

  vault_servers = {
    for n in range(var.n_vault_nodes) : "${var.vault_node_prefix}-${n}" => {
      name      = "${var.vault_node_prefix}-${n}"
      fqdn      = "${var.vault_node_prefix}-${n}.${var.network_domain}"
      ip        = "${cidrhost(var.network_cidr, n + 20)}"
      volume    = "${var.vault_node_prefix}-${n}.qcow2"
      cloudinit = "${var.vault_node_prefix}-${n}-cloudinit.iso"
      ssh_key   = tls_private_key.ssh.public_key_openssh
      index     = n
    }
  }

  prometheus_server = {
    name      = "prometheus"
    fqdn      = "prometheus.${var.network_domain}"
    ip        = "${cidrhost(var.network_cidr, 100)}"
    volume    = "prometheus.qcow2"
    cloudinit = "prometheus-cloudinit.iso"
    ssh_key   = tls_private_key.ssh.public_key_openssh
    index     = 1
  }

  grafana_server = {
    name      = "grafana"
    fqdn      = "grafana.${var.network_domain}"
    ip        = "${cidrhost(var.network_cidr, 101)}"
    volume    = "grafana.qcow2"
    cloudinit = "grafana-cloudinit.iso"
    ssh_key   = tls_private_key.ssh.public_key_openssh
    index     = 1
  }

  loki_server = {
    name      = "loki"
    fqdn      = "loki.${var.network_domain}"
    ip        = "${cidrhost(var.network_cidr, 102)}"
    volume    = "loki.qcow2"
    cloudinit = "loki-cloudinit.iso"
    ssh_key   = tls_private_key.ssh.public_key_openssh
    index     = 1
  }

  mattermost_server = {
    name      = "mattermost"
    fqdn      = "mattermost.${var.network_domain}"
    ip        = "${cidrhost(var.network_cidr, 103)}"
    volume    = "mattermost.qcow2"
    cloudinit = "mattermost-cloudinit.iso"
    ssh_key   = tls_private_key.ssh.public_key_openssh
    index     = 1
  }
}

locals {
  base_volume_pool = "Ubuntu20.04"
}