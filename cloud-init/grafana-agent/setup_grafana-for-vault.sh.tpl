#!/bin/bash

set -o -e

sed -i -E "s/#MACHINE#/$(hostname)/g" /etc/grafana-agent.yaml
chown root:grafana-agent /etc/grafana-agent.yaml

CA_CERTIFICATE_DATA=$(echo "${ca_certificate}" | base64 --decode)

mkdir -p /etc/grafana-agent

jq -r .cert <<< "$CA_CERTIFICATE_DATA" | base64 -d > /etc/grafana-agent/ca.pem
jq -r .key <<< "$CA_CERTIFICATE_DATA" | base64 -d > /tmp/ca-key.pem

SAN="subjectAltName = DNS:$(hostname), DNS:localhost, IP:${machine_ip}, IP:127.0.0.1"
openssl req -newkey rsa:4096 -nodes -keyout /etc/grafana-agent/grafana-key.pem  -out /etc/grafana-agent/grafana-req.csr -subj "/CN=GrafanaAgent" -addext "$SAN" -addext 'keyUsage=critical,keyEncipherment,digitalSignature' -addext 'extendedKeyUsage=serverAuth,clientAuth'
# .... sim confusao. open ssl does not copy extensions from the request.... really?. TL;DR - Do not breathe... do not touch it! :)
# .... https://security.stackexchange.com/questions/74345/provide-subjectaltname-to-openssl-directly-on-the-command-line
openssl x509 -req -days 365000 -set_serial 01 -CAcreateserial -in /etc/grafana-agent/grafana-req.csr -out /etc/grafana-agent/grafana-cert.pem -CA /etc/grafana-agent/ca.pem -CAkey /tmp/ca-key.pem  -extensions copyext -extfile <(printf "[ copyext ]\n$SAN\nbasicConstraints=CA:FALSE\nextendedKeyUsage=serverAuth,clientAuth\nkeyUsage=critical,keyEncipherment,digitalSignature,nonRepudiation\n")
rm -rf /tmp/ca-key.pem

chown -R root:grafana-agent /etc/grafana-agent
chmod g+r /etc/grafana-agent/grafana-key.pem

sed -i -e 's/^CUSTOM_ARGS=\"/CUSTOM_ARGS=\"-server.http.enable-tls /g' /etc/default/grafana-agent

systemctl enable grafana-agent
systemctl start grafana-agent