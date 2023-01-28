locals {
  non_consul_servers = { for s in [local.prometheus_server, local.grafana_server, local.loki_server, local.mattermost_server] : s.name => s }
}

output "node-names" {
  value = [for s in merge(local.vault_servers, local.consul_servers, local.non_consul_servers) : s.name]
}

output "consul-info" {
  value = {
    for s in local.consul_servers : s.name => {
      name    = s.name
      address = s.ip
    }
  }
}

output "consul_master_token" {
  value = random_uuid.consul_master_token.result
}
output "consul_agent_server_token" {
  value = random_uuid.consul_agent_server_token.result
}

output "vault-info" {
  value = {
    for s in local.vault_servers : s.name => {
      name    = s.name
      address = s.ip
    }
  }
}

output "prometheus-info" {
  value = {
    name    = local.prometheus_server.name
    address = local.prometheus_server.ip
  }
}

output "grafana-info" {
  value = {
    name    = local.grafana_server.name
    address = local.grafana_server.ip
  }
}

output "loki-info" {
  value = {
    name    = local.loki_server.name
    address = local.loki_server.ip
  }
}

output "mattermost-info" {
  value = {
    name    = local.mattermost_server.name
    address = local.mattermost_server.ip
  }
}


