locals {
  vault_auto_unseal_servers = {
    for n in range(var.n_vault_nodes) : "${var.vault_node_prefix}-${n}" => {
      name      = "${var.vault_node_prefix}-${n}"
      fqdn      = "${var.vault_node_prefix}-${n}.${var.network_domain}"
      ip        = "${cidrhost(var.network_cidr, n + 40)}"
      volume    = "${var.vault_node_prefix}-${n}.qcow2"
      cloudinit = "${var.vault_node_prefix}-${n}-cloudinit.iso"
      ssh_key   = data.local_file.public_key.content
      index     = n
    }
  }
}

locals {
  vault_domain = "vault-as.${var.network_domain}"
}