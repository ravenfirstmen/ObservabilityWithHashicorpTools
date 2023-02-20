

resource "random_uuid" "vault_autounseal_machine_id" {
  for_each = local.vault_auto_unseal_servers
}

data "template_cloudinit_config" "vault_autounseal_config" {
  for_each = local.vault_auto_unseal_servers

  gzip          = false # does not work with NoCloud ds?!?
  base64_encode = false # does not work with NoCloud ds?!?

  part {
    content_type = "text/cloud-config"
    content      = <<EOT
#cloud-config

preserve_hostname: false
hostname: ${each.value.name}
fqdn: ${each.value.fqdn}
prefer_fqdn_over_hostname: true

ssh_pwauth: True
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: ubuntu
      type: text  

ssh_authorized_keys:
  - "${each.value.ssh_key}"  

ca_certs:
  trusted:
    - |
      ${indent(6, data.local_file.ca_public_key.content)}

write_files:
  - encoding: b64
    content: ${data.local_file.ca_public_key.content_base64}
    path: /etc/consul.d/certs/ca.pem
  - encoding: b64
    content: ${data.local_file.ca_private_key.content_base64}
    path: /tmp/ca-key.pem
  - encoding: b64
    content: ${base64encode(templatefile("${var.base_cloud_init_folder}/grafana-agent/grafana-agent-for-vault.yaml", { role = "vault", prometheus_endpoint = var.prometheus_endpoint, loki_endpoint = var.loki_endpoint }))}
    path: /etc/grafana-agent.yaml
  - encoding: b64
    content: ${base64encode(file("${path.module}/vault/unseal.sh"))}
    path: /home/ubuntu/unseal.sh
    owner: ubuntu:ubuntu
    permissions: '0700'    
EOT
  }

  part {
    content_type = "text/x-shellscript-per-instance"
    content = templatefile("${path.module}/vault/setup_vault_server.sh.tpl",
      {
        vault_certificates_data = local.vault_certificates

        vault_storage_backend_token = data.consul_acl_token_secret_id.vault_autounseal_storage_backend.secret_id
        vault_kv_path               = "vault-autounseal"
        consul_cluster_end_point    = "${var.consul_cluster_end_point}:8501"

        vault_cluster_end_point   = var.vault_cluster_end_point
        vault_autounseal_token    = var.vault_autounseal_token
        vault_transit_key_name    = var.vault_transit_key_name
        vault_transit_mount_point = var.vault_transit_mount_point
    })
  }

  part {
    content_type = "text/x-shellscript-per-instance"
    content      = templatefile("${var.base_cloud_init_folder}/grafana-agent/setup_grafana-for-vault.sh.tpl", { machine_ip = each.value.ip, ca_certificate = local.ca_certificate })
  }

}

resource "libvirt_cloudinit_disk" "vault_autounseal_cloudinit" {
  for_each = local.vault_auto_unseal_servers

  name           = each.value.cloudinit
  meta_data      = templatefile("${var.base_cloud_init_folder}/meta_data.cfg.tpl", { machine_id = random_uuid.vault_autounseal_machine_id[each.key].result, hostname = each.value.name })
  user_data      = data.template_cloudinit_config.vault_autounseal_config[each.key].rendered
  network_config = templatefile("${var.base_cloud_init_folder}/network_config.cfg.tpl", {})
  pool           = libvirt_pool.hashicorp.name
}

resource "libvirt_domain" "vault-instance" {
  for_each = local.vault_auto_unseal_servers

  autostart = false
  name      = each.value.name
  memory    = "2048"
  vcpu      = 1
  machine   = "q35"
  xml { # para a q35 o cdrom necessita de ser sata
    xslt = file("../lib-virt/q35-cdrom-model.xslt")
  }
  qemu_agent = true

  cpu {
    mode = "host-passthrough"
  }

  firmware  = "${local.uefi_location_files}/OVMF_CODE.fd"
  cloudinit = libvirt_cloudinit_disk.vault_autounseal_cloudinit[each.key].id

  network_interface {
    network_name   = var.network_name
    hostname       = each.value.name
    addresses      = [each.value.ip]
    wait_for_lease = true
  }


  disk {
    volume_id = libvirt_volume.vault_autounseal[each.key].id
  }

  graphics {
    type = "spice"
  }

  depends_on = [
    libvirt_cloudinit_disk.vault_autounseal_cloudinit,
  ]

  # lifecycle {
  #   create_before_destroy = true
  # }
}

resource "libvirt_volume" "vault_autounseal" {
  for_each = local.vault_auto_unseal_servers

  name             = each.value.name
  pool             = libvirt_pool.hashicorp.name
  base_volume_pool = local.base_volume_pool
  base_volume_name = var.vault_volume_name
}

# Consul backend
resource "consul_acl_policy" "vault_autounseal_storage_backend" {
  name        = "vaul-auto-unseal-backend-policy"
  description = "Backend access policy for the vault unseal cluster"
  rules       = <<-RULE
    {
        "key_prefix": {
            "vault_autounseal/": {
            "policy": "write"
            }
        },
        "service": {
            "vault": {
            "policy": "write"
            }
        },
        "agent_prefix": {
            "": {
            "policy": "read"
            }
        },
        "session_prefix": {
            "": {
            "policy": "write"
            }
        }
    }
    RULE
  datacenters = [var.consul_datacenter_name]

}

resource "consul_acl_token" "vault_autounseal_storage_backend" {

  description = "Backend access token for the vault cluster"
  policies    = [consul_acl_policy.vault_autounseal_storage_backend.name]
}

data "consul_acl_token_secret_id" "vault_autounseal_storage_backend" {
  accessor_id = consul_acl_token.vault_autounseal_storage_backend.id
}

output "vault_autounseal_storage_backend_token" {
  value     = data.consul_acl_token_secret_id.vault_autounseal_storage_backend.secret_id
  sensitive = true
}