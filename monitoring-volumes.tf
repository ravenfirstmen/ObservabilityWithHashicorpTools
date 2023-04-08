
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

resource "libvirt_volume" "postgres" {
  #   # workaround: depend on libvirt_ignition.ignition[each.key], otherwise the VM will use the old disk when the user-data changes
  #   name           = "${each.value.name}-${md5(libvirt_ignition.worker_node_ignition[each.key].id)}.qcow2"
  name             = local.postgres_server.volume
  pool             = libvirt_pool.monitoring.name
  base_volume_pool = local.base_volume_pool
  base_volume_name = var.postgres_volume_name
}
