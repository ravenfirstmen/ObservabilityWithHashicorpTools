data "vault_auth_backend" "cert" {
  path = var.services_cert_path
}

resource "vault_pki_secret_backend_cert" "cert" {
  backend = var.pki_path
  name    = var.pki_role

  common_name = var.service_name
}

resource "vault_cert_auth_backend_role" "cert" {
  name        = var.service_name
  certificate = vault_pki_secret_backend_cert.cert.certificate
  backend     = data.vault_auth_backend.cert.path

  depends_on = [
    vault_pki_secret_backend_cert.cert
  ]
}
