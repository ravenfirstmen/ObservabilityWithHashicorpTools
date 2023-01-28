resource "libvirt_pool" "hashicorp" {
  name = "hashicorp-pool"
  type = "dir"
  path = "/Work/KVM/pools/hashicorp"
}

resource "libvirt_volume" "consul" {
  for_each = local.consul_servers

  name             = each.value.name
  pool             = libvirt_pool.hashicorp.name
  base_volume_pool = local.base_volume_pool
  base_volume_name = var.consul_volume_name
}

resource "libvirt_volume" "vault" {
  for_each = local.vault_servers

  name             = each.value.name
  pool             = libvirt_pool.hashicorp.name
  base_volume_pool = local.base_volume_pool
  base_volume_name = var.vault_volume_name
}

