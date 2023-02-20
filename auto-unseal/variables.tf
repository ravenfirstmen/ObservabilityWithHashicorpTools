variable "prometheus_endpoint" {
  type = string
}

variable "loki_endpoint" {
  type = string
}

variable "network_cidr" {
  type    = string
  default = "192.168.150.0/24"
}

variable "network_domain" {
  type    = string
  default = "obs.local"
}

variable "network_name" {
  type = string
}

variable "base_cloud_init_folder" {
  type = string
}

variable "ca_private_key_file" {
  type = string
}

variable "ca_public_key_file" {
  type = string
}

variable "ssh_public_key_file" {
  type = string
}

variable "n_vault_nodes" {
  type    = number
  default = 3
}

variable "consul_cluster_end_point" {
  type = string
}

variable "consul_management_token" {
  type      = string
  sensitive = true
}

variable "consul_datacenter_name" {
  type = string
}

variable "vault_node_prefix" {
  type    = string
  default = "vault-node-as"
}

variable "vault_volume_name" {
  type    = string
  default = "Ubuntu-20.04-LTS-With-Vault.qcow2"
}

variable "vault_cluster_end_point" {
  type = string
}

variable "vault_autounseal_token" {
  type      = string
  sensitive = true
}

variable "vault_transit_key_name" {
  type = string
}

variable "vault_transit_mount_point" {
  type = string
}
