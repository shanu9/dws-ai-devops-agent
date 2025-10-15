output "data_factory_id" {
  description = "Data Factory ID"
  value       = azurerm_data_factory.main.id
}

output "data_factory_name" {
  description = "Data Factory name"
  value       = azurerm_data_factory.main.name
}

output "data_factory_identity" {
  description = "Data Factory managed identity"
  value = {
    principal_id = azurerm_data_factory.main.identity[0].principal_id
    tenant_id    = azurerm_data_factory.main.identity[0].tenant_id
  }
}

output "integration_runtime_id" {
  description = "Azure Integration Runtime ID"
  value       = var.enable_azure_ir ? azurerm_data_factory_integration_runtime_azure.main[0].id : null
}

output "private_endpoint_ip" {
  description = "Private endpoint IP"
  value       = azurerm_private_endpoint.datafactory.private_service_connection[0].private_ip_address
}