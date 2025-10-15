output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_dfs_endpoint" {
  description = "Primary Data Lake endpoint"
  value       = azurerm_storage_account.main.primary_dfs_endpoint
}

output "container_names" {
  description = "Created container names"
  value       = keys(azurerm_storage_container.containers)
}

output "private_endpoint_ips" {
  description = "Private endpoint IP addresses"
  value = {
    blob = var.enable_blob_private_endpoint ? azurerm_private_endpoint.blob[0].private_service_connection[0].private_ip_address : null
    dfs  = var.enable_dfs_private_endpoint && var.enable_hierarchical_namespace ? azurerm_private_endpoint.dfs[0].private_service_connection[0].private_ip_address : null
    file = var.enable_file_private_endpoint ? azurerm_private_endpoint.file[0].private_service_connection[0].private_ip_address : null
  }
}