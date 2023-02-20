#!/usr/bin/env bash

mkdir -p /opt/keycloak/conf/tls
chmod 0755 /opt/keycloak/conf/tls

# the key.pem should be readable by the keycloak group only
touch /opt/keycloak/conf/tls/keycloak-cert-key.pem
chown root:keycloak /opt/keycloak/conf/tls/keycloak-cert-key.pem
chmod 0640 /opt/keycloak/conf/tls/keycloak-cert-key.pem

CERTIFICATES_DATA=$(echo "${certificates_data}" | base64 --decode)

jq -r .keycloak_cert <<< "$CERTIFICATES_DATA" | base64 -d > /opt/keycloak/conf/tls/keycloak-cert.pem
jq -r .keycloak_ca <<< "$CERTIFICATES_DATA" | base64 -d > /opt/keycloak/conf/tls/keycloak-ca.pem
jq -r .keycloak_pk <<< "$CERTIFICATES_DATA" | base64 -d > /opt/keycloak/conf/tls/keycloak-cert-key.pem

cat <<'EOF' | tee -a /opt/keycloak/conf/keycloak.conf

## -- === CUSTOM

https-certificate-file=/opt/keycloak/conf/tls/keycloak-cert.pem
https-certificate-key-file=/opt/keycloak/conf/tls/keycloak-cert-key.pem
hostname=${hostname}
EOF

cd /opt/keycloak
./bin/kc.sh build

systemctl enable keycloak
systemctl start keycloak
