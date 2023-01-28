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
      source = "grafana/grafana"
      version = "1.34.0"
    }    
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

