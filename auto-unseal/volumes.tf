locals {
  base_volume_pool    = "Ubuntu20.04"
  uefi_location_files = "/usr/share/OVMF"
  #nvram_location = "/var/lib/libvirt/qemu/nvram"
}

resource "libvirt_pool" "hashicorp" {
  name = "hashicorp-pool-autounseal"
  type = "dir"
  path = "/Work/KVM/pools/hashicorp-autounseal"
}

resource "libvirt_volume" "vault" {
  for_each = local.vault_auto_unseal_servers

  name             = each.value.name
  pool             = libvirt_pool.hashicorp.name
  base_volume_pool = local.base_volume_pool
  base_volume_name = var.vault_volume_name
}

