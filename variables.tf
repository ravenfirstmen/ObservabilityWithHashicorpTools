variable "network_cidr" {
  type    = string
  default = "192.168.150.0/24"
}

variable "network_domain" {
  type    = string
  default = "obs.local"
}


variable "n_consul_nodes" {
  type    = number
  default = 1
}

variable "consul_node_prefix" {
  type    = string
  default = "consul-node"
}

variable "n_vault_nodes" {
  type    = number
  default = 3
}

variable "vault_node_prefix" {
  type    = string
  default = "vault-node"
}

variable "vault_volume_name" {
  type    = string
  default = "Ubuntu-20.04-LTS-With-Vault.qcow2"
}

variable "consul_volume_name" {
  type    = string
  default = "Ubuntu-20.04-LTS-With-Consul.qcow2"
}

variable "prometheus_volume_name" {
  type    = string
  default = "Ubuntu-20.04-LTS-With-Prometheus.qcow2"
}

variable "grafana_volume_name" {
  type    = string
  default = "Ubuntu-20.04-LTS-With-Grafana.qcow2"
}

variable "loki_volume_name" {
  type    = string
  default = "Ubuntu-20.04-LTS-With-Loki.qcow2"
}

variable "mattermost_volume_name" {
  type    = string
  default = "Ubuntu-20.04-LTS-With-Mattermost.qcow2"
}

variable "keycloak_volume_name" {
  type    = string
  default = "Ubuntu-20.04-LTS-With-KeyCloak.qcow2"
}

variable "postgres_volume_name" {
  type    = string
  default = "Ubuntu-20.04-LTS-With-Postgres.qcow2"
}

variable "datacenter_name" {
  type    = string
  default = "consul-dc1"
}

variable "consul_cluster_version" {
  default     = "0.0.1"
  description = "Custom Version Tag for Upgrade Migrations"
}

variable "acl_bootstrap_bool" {
  type        = bool
  default     = true
  description = "Initial ACL Bootstrap configurations"
}

variable "is_integrated_storage" {
  type        = bool
  default     = false
  description = "True to use integrated storage"
}

variable "is_consul_vault_backend" {
  type        = bool
  default     = false
  description = "True if consul is vault backend"
}

variable "is_postgres_storage" {
  type        = bool
  default     = true
  description = "True if postgres is vault backend"
}
