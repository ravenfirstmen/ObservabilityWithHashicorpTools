resource "random_uuid" "keycloak_machine_id" {
}

resource "random_password" "keycloak_password" {
  length  = 12
  special = false
}

data "template_cloudinit_config" "keycloak_config" {
  gzip          = false # does not work with NoCloud ds?!?
  base64_encode = false # does not work with NoCloud ds?!?

  part {
    content_type = "text/cloud-config"
    content      = <<EOT
#cloud-config

preserve_hostname: false
hostname: ${local.keycloak_server.name}
fqdn: ${local.keycloak_server.fqdn}
prefer_fqdn_over_hostname: true

ssh_pwauth: True
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: ubuntu
      type: text  

ssh_authorized_keys:
  - "${local.keycloak_server.ssh_key}"  

ca_certs:
  trusted:
    - |
      ${indent(6, tls_self_signed_cert.ca_cert.cert_pem)}

write_files:
  - encoding: b64
    content: ${base64encode(templatefile("${path.module}/cloud-init/keycloak/credentials.env.tpl", { password = random_password.keycloak_password.result }))}
    path: /etc/default/keycloak.env
    owner: root:root
    permissions: '0600'

EOT
  }

  part {
    content_type = "text/x-shellscript-per-instance"
    content = templatefile("${path.module}/cloud-init/keycloak/setup-keycloak.sh.tpl",
      {
        certificates_data = local.keycloak_certificates,
        hostname          = local.keycloak_server.fqdn
    })
  }

  part {
    content_type = "text/x-shellscript-per-instance"
    content      = templatefile("${path.module}/cloud-init/grafana-agent/setup_grafana.sh.tpl", {})
  }

}

resource "libvirt_cloudinit_disk" "keycloak_cloudinit" {

  name           = local.keycloak_server.cloudinit
  meta_data      = templatefile("${path.module}/cloud-init/meta_data.cfg.tpl", { machine_id = random_uuid.keycloak_machine_id.result, hostname = local.keycloak_server.name })
  user_data      = data.template_cloudinit_config.keycloak_config.rendered
  network_config = templatefile("${path.module}/cloud-init/network_config.cfg.tpl", {})
  pool           = libvirt_pool.hashicorp.name
}

resource "libvirt_domain" "keycloak_instance" {

  autostart = false
  name      = local.keycloak_server.name
  memory    = "2048"
  vcpu      = 1
  machine   = "q35"
  xml { # para a q35 o cdrom necessita de ser sata
    xslt = file("lib-virt/q35-cdrom-model.xslt")
  }
  qemu_agent = true

  cpu {
    mode = "host-passthrough"
  }

  firmware  = "${local.uefi_location_files}/OVMF_CODE.fd"
  cloudinit = libvirt_cloudinit_disk.keycloak_cloudinit.id

  network_interface {
    network_id     = libvirt_network.observability_network.id
    hostname       = local.keycloak_server.name
    addresses      = [local.keycloak_server.ip]
    wait_for_lease = true
  }


  disk {
    volume_id = libvirt_volume.keycloak.id
  }

  graphics {
    type = "spice"
  }

  depends_on = [
    libvirt_cloudinit_disk.keycloak_cloudinit,
  ]

  # lifecycle {
  #   create_before_destroy = true
  # }
}

resource "libvirt_volume" "keycloak" {
  name             = local.keycloak_server.name
  pool             = libvirt_pool.hashicorp.name
  base_volume_pool = local.base_volume_pool
  base_volume_name = var.keycloak_volume_name
}
