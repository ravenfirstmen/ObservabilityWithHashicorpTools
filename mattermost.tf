resource "random_uuid" "mattermost_machine_id" {
}

data "template_cloudinit_config" "mattermost_config" {
  gzip          = false # does not work with NoCloud ds?!?
  base64_encode = false # does not work with NoCloud ds?!?

  part {
    content_type = "text/cloud-config"
    content      = <<EOT
#cloud-config

preserve_hostname: false
hostname: ${local.mattermost_server.name}
fqdn: ${local.mattermost_server.fqdn}
prefer_fqdn_over_hostname: true

ssh_pwauth: True
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: ubuntu
      type: text  

ssh_authorized_keys:
  - "${local.mattermost_server.ssh_key}"  

ca_certs:
  trusted:
    - |
      ${indent(6, tls_self_signed_cert.ca_cert.cert_pem)}
EOT
  }
  part {
    content_type = "text/x-shellscript-per-instance"
    content      = <<EOT
#!/bin/bash
set -o -e
systemctl start mattermost
    EOT
  }
}

resource "libvirt_cloudinit_disk" "mattermost_cloudinit" {

  name           = local.mattermost_server.cloudinit
  meta_data      = templatefile("${path.module}/cloud-init/meta_data.cfg.tpl", { machine_id = random_uuid.mattermost_machine_id.result, hostname = local.mattermost_server.name })
  user_data      = data.template_cloudinit_config.mattermost_config.rendered
  network_config = templatefile("${path.module}/cloud-init/network_config.cfg.tpl", {})
  pool           = libvirt_pool.monitoring.name
}

resource "libvirt_domain" "mattermost_instance" {

  autostart = false
  name      = local.mattermost_server.name
  memory    = "4096"
  vcpu      = 2
  machine   = "q35"
  xml { # para a q35 o cdrom necessita de ser sata
    xslt = file("lib-virt/q35-cdrom-model.xslt")
  }
  qemu_agent = true

  cpu {
    mode = "host-passthrough"
  }

  firmware  = "${local.uefi_location_files}/OVMF_CODE.fd"
  cloudinit = libvirt_cloudinit_disk.mattermost_cloudinit.id

  network_interface {
    network_id     = libvirt_network.observability_network.id
    hostname       = local.mattermost_server.name
    addresses      = [local.mattermost_server.ip]
    wait_for_lease = true
  }


  disk {
    volume_id = libvirt_volume.mattermost.id
  }

  graphics {
    type = "spice"
  }

  depends_on = [
    libvirt_cloudinit_disk.mattermost_cloudinit
  ]

  # lifecycle {
  #   create_before_destroy = true
  # }
}


