data "vault_auth_backend" "approle" {
  path = var.services_approle_path
}

resource "vault_approle_auth_backend_role" "service_role" {
  backend   = data.vault_auth_backend.approle.path
  role_name = var.service_name
}

resource "vault_approle_auth_backend_role_secret_id" "service_role" {
  depends_on = [
    vault_approle_auth_backend_role.service_role
  ]
  backend   = data.vault_auth_backend.approle.path
  role_name = var.service_name
}