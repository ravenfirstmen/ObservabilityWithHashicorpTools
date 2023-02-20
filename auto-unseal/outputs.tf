output "auto-unseal-vault-node-names" {
  value = [for s in local.vault_auto_unseal_servers : s.name]
}

output "vault-nodes-info" {
  value = {
    for s in local.vault_auto_unseal_servers : s.name => {
      name    = s.name
      address = s.ip
    }
  }
}
