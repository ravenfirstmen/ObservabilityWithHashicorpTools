resource "vault_policy" "kvv2_services_policy" {
  name = "kvv2-secrets-policy"

  policy = <<EOT
path "${vault_mount.kvv2.path}/data/{{identity.entity.name}}/*" {
  capabilities = ["create", "update", "patch", "read", "delete"]
}
path "${vault_mount.kvv2.path}/metadata/{{identity.entity.name}}/*" {
  capabilities = ["list"]
}
EOT
}


resource "vault_policy" "aws_policies" {
  name = "aws-secrets-policy"

  policy = <<EOT
path "${vault_aws_secret_backend.aws.path}/+/{{identity.entity.name}}" {
  capabilities = ["create", "update", "patch", "read", "delete", "list"]
}
EOT
}


resource "vault_policy" "transit_policies" {
  name = "transit-secret-policy"

  policy = <<EOT
path "${vault_mount.transit.path}/encrypt/${vault_transit_secret_backend_key.key.name}" {
   capabilities = [ "update" ]
}

path "${vault_mount.transit.path}/decrypt/${vault_transit_secret_backend_key.key.name}" {
   capabilities = [ "update" ]
}
EOT
}
