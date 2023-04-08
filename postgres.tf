resource "random_uuid" "posgres_machine_id" {
}

resource "random_password" "posgres_password" {
  length  = 12
  special = false
}

resource "libvirt_cloudinit_disk" "postgres_cloudinit" {
  name           = local.postgres_server.cloudinit
  pool           = libvirt_pool.monitoring.name
  meta_data      = templatefile("${path.module}/cloud-init/meta_data.cfg.tpl", { machine_id = random_uuid.posgres_machine_id.result, hostname = local.postgres_server.name })
  network_config = templatefile("${path.module}/cloud-init/network_config.cfg.tpl", {})

  user_data = data.template_cloudinit_config.postgres_config.rendered
}


data "template_cloudinit_config" "postgres_config" {
  gzip          = false # does not work with NoCloud ds?!?
  base64_encode = false # does not work with NoCloud ds?!?

  part {
    content_type = "text/cloud-config"
    content      = <<EOT
#cloud-config

preserve_hostname: false
hostname: ${local.postgres_server.name}
fqdn: ${local.postgres_server.fqdn}
prefer_fqdn_over_hostname: true

ssh_pwauth: True
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: ubuntu
      type: text  

ssh_authorized_keys:
  - "${local.postgres_server.ssh_key}"  

ca_certs:
  trusted:
    - |
      ${indent(6, tls_self_signed_cert.ca_cert.cert_pem)}

EOT
  }

  part {
    content_type = "text/x-shellscript-per-instance"
    content      = templatefile("${path.module}/cloud-init/postgres/setup_postgres.sh.tpl", { pg_passwd = random_password.posgres_password.result })
  }
}


resource "libvirt_domain" "postgres-machine" {

  name   = local.postgres_server.name
  memory = "2048"
  vcpu   = 2

  autostart = false
  machine   = "q35"

  xml { # para a q35 o cdrom necessita de ser sata
    xslt = file("lib-virt/q35-cdrom-model.xslt")
  }
  qemu_agent = true

  firmware  = "${local.uefi_location_files}/OVMF_CODE.fd"
  cloudinit = libvirt_cloudinit_disk.postgres_cloudinit.id

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.postgres.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  network_interface {
    network_id     = libvirt_network.observability_network.id
    hostname       = local.postgres_server.name
    addresses      = [local.postgres_server.ip]
    wait_for_lease = true
  }

  depends_on = [
    libvirt_cloudinit_disk.postgres_cloudinit
  ]
}


