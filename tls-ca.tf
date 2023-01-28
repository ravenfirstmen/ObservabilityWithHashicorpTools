
resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem   = tls_private_key.ca_key.private_key_pem
  is_ca_certificate = true

  subject {
    common_name  = "Observability CA"
    organization = "Virtual"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]
}

resource "local_file" "ca_private_key" {
  content         = tls_private_key.ca_key.private_key_pem
  filename        = "./certs/ca-key.pem"
  file_permission = "0600"
}

resource "local_file" "ca_public_key" {
  content         = tls_self_signed_cert.ca_cert.cert_pem
  filename        = "./certs/ca.pem"
  file_permission = "0600"
}

locals {
  ca_certificate_data = {
    cert = base64encode(tls_self_signed_cert.ca_cert.cert_pem)
    key  = base64encode(tls_private_key.ca_key.private_key_pem)
  }
}

locals {
  ca_certificate = base64encode(jsonencode(local.ca_certificate_data))
}