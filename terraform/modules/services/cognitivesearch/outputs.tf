# =============================================================================
# COGNITIVE SEARCH MODULE OUTPUTS
# =============================================================================

output "search_service_id" {
  description = "Search service ID"
  value       = azurerm_search_service.main.id
}

output "search_service_name" {
  description = "Search service name"
  value       = azurerm_search_service.main.name
}

output "search_service_endpoint" {
  description = "Search service endpoint"
  value       = "https://${azurerm_search_service.main.name}.search.windows.net"
}

output "primary_key" {
  description = "Primary admin key"
  value       = azurerm_search_service.main.primary_key
  sensitive   = true
}

output "secondary_key" {
  description = "Secondary admin key"
  value       = azurerm_search_service.main.secondary_key
  sensitive   = true
}

output "query_keys" {
  description = "Query keys for read-only access"
  value       = azurerm_search_service.main.query_keys
  sensitive   = true
}

output "identity" {
  description = "Managed identity"
  value = var.enable_customer_managed_key ? {
    principal_id = azurerm_search_service.main.identity[0].principal_id
    tenant_id    = azurerm_search_service.main.identity[0].tenant_id
  } : null
}

output "private_endpoint_id" {
  description = "Private endpoint ID"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.search[0].id : null
}