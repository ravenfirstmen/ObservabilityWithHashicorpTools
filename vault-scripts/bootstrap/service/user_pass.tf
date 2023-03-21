data "vault_auth_backend" "userpass" {
  path = var.services_userpass_path
}

resource "vault_generic_endpoint" "service_user_pass" {
  path                 = "auth/${var.services_userpass_path}/users/${var.service_name}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "password": "changeme"
}
EOT
}