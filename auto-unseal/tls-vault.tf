resource "tls_private_key" "vault_cluster_server_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "vault_cluster_cert" {
  private_key_pem = tls_private_key.vault_cluster_server_key.private_key_pem

  subject {
    common_name  = local.vault_domain
    organization = "Virtual"
  }

  dns_names = concat(
    [for s in local.vault_auto_unseal_servers : s.fqdn],
    [
      local.vault_domain,
      "localhost"
    ]
  )
  ip_addresses = concat(
    [for s in local.vault_auto_unseal_servers : s.ip],
    ["127.0.0.1"]
  )
}

resource "tls_locally_signed_cert" "vault_cluster_server_signed_cert" {
  cert_request_pem = tls_cert_request.vault_cluster_cert.cert_request_pem

  ca_private_key_pem = data.local_file.ca_private_key.content
  ca_cert_pem        = data.local_file.ca_public_key.content

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "client_auth",
    "key_agreement",
    "server_auth",
  ]

  validity_period_hours = 8760
}

resource "local_file" "vault_private_key" {
  content         = tls_private_key.vault_cluster_server_key.private_key_pem
  filename        = "./vault-cert-key.pem"
  file_permission = "0600"
}

resource "local_file" "vault_public_key" {
  content         = tls_locally_signed_cert.vault_cluster_server_signed_cert.cert_pem
  filename        = "./vault-cert.pem"
  file_permission = "0600"
}


locals {
  vault_certificates_data = {
    vault_ca   = data.local_file.ca_public_key.content_base64
    vault_cert = base64encode(tls_locally_signed_cert.vault_cluster_server_signed_cert.cert_pem)
    vault_pk   = base64encode(tls_private_key.vault_cluster_server_key.private_key_pem)
  }
}

locals {
  vault_certificates = base64encode(jsonencode(local.vault_certificates_data))
}