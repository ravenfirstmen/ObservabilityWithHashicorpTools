module "antonio" {
  source = "./service"

  service_name           = "antonio"
  services_approle_path  = vault_auth_backend.services_approle.path
  services_userpass_path = vault_auth_backend.services_userpass.path
  services_cert_path     = vault_auth_backend.services_cert.path

  pki_path                = vault_mount.pki.path
  pki_role                = vault_pki_secret_backend_role.client_certificates.name
  aws_secrets_path        = vault_aws_secret_backend.aws.path
  service_kv_policy_name  = vault_policy.kvv2_services_policy.name
  service_aws_policy_name = vault_policy.aws_policies.name

  depends_on = [
    vault_auth_backend.services_approle,
    vault_auth_backend.services_userpass,
    vault_auth_backend.services_cert,
    vault_pki_secret_backend_role.client_certificates
  ]
}

output "antonio_service_name" {
  value = "antonio"
}

output "antonio_approle_role_id" {
  value = module.antonio.approle_role_id
}

output "antonio_approle_secret_id" {
  value     = module.antonio.approle_secret_id
  sensitive = true
}

output "antonio_userpass_username" {
  value = module.antonio.userpass_username
}

output "antonio_userpass_password" {
  value = module.antonio.userpass_password
}

output "antonio_cert_cert" {
  value = module.antonio.cert_cert
}

output "antonio_cert_key" {
  value = module.antonio.cert_key
}

#######################

module "salgado" {
  source = "./service"

  service_name           = "salgado"
  services_approle_path  = vault_auth_backend.services_approle.path
  services_userpass_path = vault_auth_backend.services_userpass.path
  services_cert_path     = vault_auth_backend.services_cert.path

  pki_path                = vault_mount.pki.path
  pki_role                = vault_pki_secret_backend_role.client_certificates.name
  aws_secrets_path        = vault_aws_secret_backend.aws.path
  service_kv_policy_name  = vault_policy.kvv2_services_policy.name
  service_aws_policy_name = vault_policy.aws_policies.name

  depends_on = [
    vault_auth_backend.services_approle,
    vault_auth_backend.services_userpass,
    vault_auth_backend.services_cert,
    vault_pki_secret_backend_role.client_certificates
  ]
}

output "salgado_service_name" {
  value = "salgado"
}

output "salgado_approle_role_id" {
  value = module.salgado.approle_role_id
}

output "salgado_approle_secret_id" {
  value     = module.salgado.approle_secret_id
  sensitive = true
}

output "salgado_userpass_username" {
  value = module.salgado.userpass_username
}

output "salgado_userpass_password" {
  value = module.salgado.userpass_password
}

output "salgado_cert_cert" {
  value = module.salgado.cert_cert
}

output "salgado_cert_key" {
  value = module.salgado.cert_key
}