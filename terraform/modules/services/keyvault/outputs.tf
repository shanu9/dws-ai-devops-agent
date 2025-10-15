output "keyvault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.main.id
}

output "keyvault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "keyvault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

output "private_endpoint_ip" {
  description = "Private endpoint IP"
  value       = azurerm_private_endpoint.keyvault.private_service_connection[0].private_ip_address
}