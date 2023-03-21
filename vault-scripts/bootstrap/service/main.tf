resource "vault_identity_entity" "service_entity" {
  name     = var.service_name
  policies = [var.service_kv_policy_name, var.service_aws_policy_name]
  metadata = {
    service = var.service_name
    team    = var.service_name
  }
}

resource "vault_identity_entity_alias" "approle" {
  #name           = var.service_name
  name           = vault_approle_auth_backend_role.service_role.role_id
  mount_accessor = data.vault_auth_backend.approle.accessor
  canonical_id   = vault_identity_entity.service_entity.id
}

resource "vault_identity_entity_alias" "userpass" {
  name           = var.service_name
  mount_accessor = data.vault_auth_backend.userpass.accessor
  canonical_id   = vault_identity_entity.service_entity.id
}

resource "vault_identity_entity_alias" "cert" {
  name           = var.service_name
  mount_accessor = data.vault_auth_backend.cert.accessor
  canonical_id   = vault_identity_entity.service_entity.id
}
