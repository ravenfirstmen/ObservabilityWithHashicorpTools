resource "vault_mount" "kvv2" {
  path        = "kv"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_mount" "pki" {
  path        = "pki"
  type        = "pki"
  description = "PKI mount"

  default_lease_ttl_seconds = 60 * 60 * 24 * 30 * 365
  max_lease_ttl_seconds     = 60 * 60 * 24 * 30 * 365
}

resource "vault_aws_secret_backend" "aws" {
  access_key = "AKIA....."
  secret_key = "AWS secret key"
  path       = "aws"
}


resource "vault_mount" "transit" {
  path                      = "transit"
  type                      = "transit"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 3600
}

resource "vault_transit_secret_backend_key" "key" {
  backend = vault_mount.transit.path
  name    = "enc-key"
  deletion_allowed = true
}