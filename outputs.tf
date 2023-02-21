locals {
  non_consul_servers = { for s in [local.prometheus_server, local.grafana_server, local.loki_server, local.mattermost_server, local.keycloak_server] : s.name => s }
  all_servers        = merge(local.vault_servers, local.consul_servers, local.non_consul_servers)
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


output "keyclock-info" {
  value = {
    name    = local.keycloak_server.name
    address = local.keycloak_server.ip
  }
}

output "network_cidr" {
  value = var.network_cidr
}
output "network_domain" {
  value = var.network_domain
}
output "network_name" {
  value = libvirt_network.observability_network.name
}

output "keycloak_password" {
  value     = random_password.keycloak_password.result
  sensitive = true
}

output "etc_hosts" {
  value = <<EOF
  #Add these to your /etc/hosts
  ${local.first_consul_server.ip}	consul		        consul.${var.network_domain}
  ${local.first_vault_server.ip}	vault		          vault.${var.network_domain}
  %{~for s in local.all_servers~}
  ${format("%s\t%s\t\t%s", s.ip, s.name, s.fqdn)}
  %{~endfor~}
  EOF
}

