
resource "libvirt_pool" "monitoring" {
  name = "monitoring-pool"
  type = "dir"
  path = "/Work/KVM/pools/monitoring"
}

resource "libvirt_volume" "prometheus" {
  name             = local.prometheus_server.name
  pool             = libvirt_pool.monitoring.name
  base_volume_pool = local.base_volume_pool
  base_volume_name = var.prometheus_volume_name
}

resource "libvirt_volume" "grafana" {
  name             = local.grafana_server.name
  pool             = libvirt_pool.monitoring.name
  base_volume_pool = local.base_volume_pool
  base_volume_name = var.grafana_volume_name
}

resource "libvirt_volume" "loki" {
  name             = local.loki_server.name
  pool             = libvirt_pool.monitoring.name
  base_volume_pool = local.base_volume_pool
  base_volume_name = var.loki_volume_name
}

resource "libvirt_volume" "mattermost" {
  name             = local.mattermost_server.name
  pool             = libvirt_pool.monitoring.name
  base_volume_pool = local.base_volume_pool
  base_volume_name = var.mattermost_volume_name
}
