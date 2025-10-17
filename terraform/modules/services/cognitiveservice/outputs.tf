# =============================================================================
# COGNITIVE SERVICES MODULE OUTPUTS
# =============================================================================

output "cognitive_account_id" {
  value = azurerm_cognitive_account.main.id
}

output "cognitive_account_name" {
  value = azurerm_cognitive_account.main.name
}

output "endpoint" {
  value = azurerm_cognitive_account.main.endpoint
}

output "primary_access_key" {
  value     = azurerm_cognitive_account.main.primary_access_key
  sensitive = true
}

output "secondary_access_key" {
  value     = azurerm_cognitive_account.main.secondary_access_key
  sensitive = true
}

output "identity" {
  value = {
    principal_id = azurerm_cognitive_account.main.identity[0].principal_id
    tenant_id    = azurerm_cognitive_account.main.identity[0].tenant_id
  }
}

output "custom_subdomain" {
  value = azurerm_cognitive_account.main.custom_subdomain_name
}

output "openai_deployment_ids" {
  value = { for k, v in azurerm_cognitive_deployment.openai : k => v.id }
}

output "private_endpoint_id" {
  value = var.enable_private_endpoint ? azurerm_private_endpoint.cognitive[0].id : null
}