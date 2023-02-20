resource "tls_private_key" "keycloak_cluster_server_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "keycloak_cluster_cert" {
  private_key_pem = tls_private_key.keycloak_cluster_server_key.private_key_pem

  subject {
    common_name  = local.keycloak_server.fqdn
    organization = "Virtual"
  }

  dns_names = [
      local.keycloak_server.fqdn,
      "localhost"
    ]
  
  ip_addresses = ["127.0.0.1"]
  
}

resource "tls_locally_signed_cert" "keycloak_cluster_server_signed_cert" {
  cert_request_pem = tls_cert_request.keycloak_cluster_cert.cert_request_pem

  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "client_auth",
    "key_agreement",
    "server_auth",
  ]

  validity_period_hours = 8760
}

resource "local_file" "keycloak_private_key" {
  content         = tls_private_key.keycloak_cluster_server_key.private_key_pem
  filename        = "./certs/keycloak-cert-key.pem"
  file_permission = "0600"
}

resource "local_file" "keycloak_public_key" {
  content         = tls_locally_signed_cert.keycloak_cluster_server_signed_cert.cert_pem
  filename        = "./certs/keycloak-cert.pem"
  file_permission = "0600"
}


locals {
  keycloak_certificates_data = {
    keycloak_ca   = base64encode(tls_self_signed_cert.ca_cert.cert_pem)
    keycloak_cert = base64encode(tls_locally_signed_cert.keycloak_cluster_server_signed_cert.cert_pem)
    keycloak_pk   = base64encode(tls_private_key.keycloak_cluster_server_key.private_key_pem)
  }
}

locals {
  keycloak_certificates = base64encode(jsonencode(local.keycloak_certificates_data))
}
