provider "vault" {
  address               = "https://192.168.150.20:8200"
  skip_tls_verify       = true
  max_lease_ttl_seconds = 600
  auth_login {
    path   = "auth/${var.login_approle_path}/login"
    method = "approle"

    parameters = {
      role_id   = var.login_approle_role_id
      secret_id = var.login_approle_secret_id
    }
  }
}
