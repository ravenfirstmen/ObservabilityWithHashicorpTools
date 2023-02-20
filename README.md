# About

Observability local stack. Uses LibVirt/KVM to provide a local environment for learning/training with Vault, Consul, Prometheus and Grafana.

- Vault (Vault service)
- Consul (Service mesh)
- Prometheus (Metrics collector and aggregator)
- Prometheus AlertManager (Alerts)
- Loki (Logs collector & aggregator)
- Grafana (Metrics & logs visualization)
- Mattermost (Messaging platform - similar to slack - as an alert notification channel)

# Why not K8s or docker?

Well... and why not VM's? K8s maybe in near future.

# Build the images (Ubuntu 20.04 based)

Clone the Github repository Packer and build the images first (https://github.com/aacs71/Packer)

```
git clone https://github.com/aacs71/Packer.git
cd Packer && packer init . && packer build .
```


# Deployment

Ensure terraform is installed (https://developer.hashicorp.com/terraform/downloads)

```
terraform init && terraform apply
```

# Unseal Vault

**NOTE:** Vault is started sealed. First unseal it

```
cd vault-scripts && ./unseal-vault.sh
```
The `unseal-info.json` contains the unseals keys and the root token


# /etc/hosts

```
192.168.150.10	consul		        consul.obs.local
192.168.150.10	consul-node-0		consul-node-0.obs.local
192.168.150.11	consul-node-1		consul-node-1.obs.local
192.168.150.12	consul-node-2		consul-node-2.obs.local
192.168.150.31	grafana		        grafana.obs.local
192.168.150.34	keycloak		    keycloak.obs.local
192.168.150.32	loki		        loki.obs.local
192.168.150.33	mattermost		    mattermost.obs.local
192.168.150.30	prometheus		    prometheus.obs.local
192.168.150.20	vault	            vault.obs.local
192.168.150.20	vault-node-0	    vault-node-0.obs.local
192.168.150.21	vault-node-1		vault-node-1.obs.local
192.168.150.22	vault-node-2		vault-node-2.obs.local

```

# Endpoints

* Consul (Service Mesh): http://consul.obs.local:8500/
* Vault (Vault service): https://vault.obs.local:8200/
* Keycloak (OIDC provider): https://keycloak.obs.local:8443/
* Grafana (metrics & logs UI) -> http://grafana.obs.local:3000/
* Prometheus (Metrics) -> http://prometheus.obs.local:9090/
* Prometheus Alertmanager (Metrics alerts) -> http://prometheus.obs.local:9093/
* Loki (logs) -> http://loki.obs.local:3100/
* Mattermost (Messaging platform - similar to Slack) -> http://mattermost.obs.local:8065/
