
resource "vault_pki_secret_backend_root_cert" "root_ca" {
  depends_on           = [vault_mount.pki]
  backend              = vault_mount.pki.path
  type                 = "internal"
  common_name          = "Root CA"
  ttl                  = "315360000"
  format               = "pem"
  private_key_format   = "der"
  key_type             = "rsa"
  key_bits             = 4096
  exclude_cn_from_sans = true
  ou                   = "My OU"
  organization         = "My organization"
}

resource "vault_pki_secret_backend_role" "client_certificates" {
  backend           = vault_mount.pki.path
  name              = "client_certificates"
  ttl               = 3600
  allow_ip_sans     = true
  key_type          = "rsa"
  key_bits          = 4096
  allow_subdomains  = false
  allow_any_name    = true
  enforce_hostnames = false
  client_flag       = true
  # key_usage = [ "DigitalSignature","KeyAgreement","KeyEncipherment" ]
  # ext_key_usage = [ "ClientAuth" ]
}
