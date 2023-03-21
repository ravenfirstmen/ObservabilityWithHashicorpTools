output "approle_role_id" {
  value = vault_approle_auth_backend_role.service_role.role_id
}

output "approle_secret_id" {
  value = vault_approle_auth_backend_role_secret_id.service_role.secret_id
}

output "userpass_username" {
  value = var.service_name
}

output "userpass_password" {
  value = "changeme"
}

output "cert_cert" {
  value = "${var.service_name}.pem"
}

output "cert_key" {
  value = "${var.service_name}-key.der"
}

resource "local_file" "cert_private_key" {
  content         = vault_pki_secret_backend_cert.cert.private_key
  filename        = "${var.service_name}-key.der"
  file_permission = "0600"
}

resource "local_file" "cert_public_key" {
  content         = vault_pki_secret_backend_cert.cert.certificate
  filename        = "${var.service_name}.pem"
  file_permission = "0600"
}