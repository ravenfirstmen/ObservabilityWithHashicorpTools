resource "libvirt_network" "observability_network" {
  name   = "observability-network"
  mode   = "nat"
  domain = var.network_domain

  addresses = [var.network_cidr]

  dns {
    enabled    = true
    local_only = true
  }
}
