#!/bin/bash

cat <<'EOT' | vault policy write reader -
path "/secret/*" {
    capabilities = ["read", "list"]
}
EOT

vault auth enable -path=keycloak oidc

vault auth tune -listing-visibility=unauth -description="Keycloak" keycloak/

vault write auth/keycloak/config oidc_discovery_url="https://keycloak.obs.local:8443/realms/vault.obs.local" oidc_client_id="vault.obs.local" oidc_client_secret="«the keycloak client id»" default_role=reader

vault write auth/keycloak/role/reader bound_audiences="vault.obs.local" \
allowed_redirect_uris="http://vault.obs.local:8250/oidc/callback" \
allowed_redirect_uris="http://localhost:8250/oidc/callback" \
allowed_redirect_uris="https://vault.obs.local:8200/ui/vault/auth/keycloak/oidc/callback" \
user_claim="sub" policies=reader