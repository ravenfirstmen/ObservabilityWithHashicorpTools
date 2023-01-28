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


# Endpoints

* Consul (Service Mesh): http://192.168.150.10:8500/
* Vault (Vault service): https://192.168.150.20:8200/
* Grafana (metrics & logs UI) -> http://192.168.150.101:3000/
* Prometheus (Metrics) -> http://192.168.150.100:9090/
* Prometheus Alertmanager (Metrics alerts) -> http://192.168.150.100:9093/
* Loki (logs) -> http://192.168.150.102:3100/
* Mattermost (Messaging platform - similar to Slack) -> http://192.168.150.103:8065/



