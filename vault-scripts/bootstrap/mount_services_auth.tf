resource "vault_auth_backend" "services_approle" {
  type = "approle"
  path = "services-approle"
}

resource "vault_auth_backend" "services_userpass" {
  type = "userpass"
  path = "services-userpass"
}

resource "vault_auth_backend" "services_cert" {
  type = "cert"
  path = "services-cert"
}

