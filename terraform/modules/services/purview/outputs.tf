# =============================================================================
# PURVIEW MODULE OUTPUTS
# =============================================================================

output "purview_account_id" {
  description = "Purview account ID"
  value       = azurerm_purview_account.main.id
}

output "purview_account_name" {
  description = "Purview account name"
  value       = azurerm_purview_account.main.name
}

output "catalog_endpoint" {
  description = "Purview catalog endpoint"
  value       = azurerm_purview_account.main.catalog_endpoint
}

output "guardian_endpoint" {
  description = "Purview guardian endpoint"
  value       = azurerm_purview_account.main.guardian_endpoint
}

output "scan_endpoint" {
  description = "Purview scan endpoint"
  value       = azurerm_purview_account.main.scan_endpoint
}

output "identity" {
  description = "Purview managed identity"
  value = {
    principal_id = azurerm_purview_account.main.identity[0].principal_id
    tenant_id    = azurerm_purview_account.main.identity[0].tenant_id
  }
}

output "managed_resource_group_name" {
  description = "Managed resource group name"
  value       = azurerm_purview_account.main.managed_resource_group_name
}

output "private_endpoint_account_id" {
  description = "Private endpoint ID for account"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.account[0].id : null
}

output "private_endpoint_portal_id" {
  description = "Private endpoint ID for portal"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.portal[0].id : null
}