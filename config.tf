terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "1.34.0"
    }
    consul = {
      source  = "hashicorp/consul"
      version = "2.17.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  first_consul_server_key  = "${var.consul_node_prefix}-0"
  consul_cluster_end_point = local.consul_servers[local.first_consul_server_key].ip
}
provider "consul" {
  address    = "${local.consul_cluster_end_point}:8500"
  datacenter = var.datacenter_name
  token      = random_uuid.consul_master_token.result
}

