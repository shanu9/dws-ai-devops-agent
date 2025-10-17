# =============================================================================
# AZURE FUNCTIONS MODULE OUTPUTS
# =============================================================================

output "function_app_id" {
  description = "Function app ID"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].id : azurerm_windows_function_app.main[0].id
}

output "function_app_name" {
  description = "Function app name"
  value       = local.function_app_name
}

output "function_app_default_hostname" {
  description = "Function app default hostname"
  value       = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].default_hostname : azurerm_windows_function_app.main[0].default_hostname
}

output "function_app_identity" {
  description = "Function app managed identity"
  value = {
    principal_id = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].identity[0].principal_id : azurerm_windows_function_app.main[0].identity[0].principal_id
    tenant_id    = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].identity[0].tenant_id : azurerm_windows_function_app.main[0].identity[0].tenant_id
  }
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.functions.name
}

output "private_endpoint_id" {
  description = "Private endpoint ID"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.functions[0].id : null
}