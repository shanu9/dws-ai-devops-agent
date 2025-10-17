# =============================================================================
# MACHINE LEARNING MODULE OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# WORKSPACE OUTPUTS
# -----------------------------------------------------------------------------

output "workspace_id" {
  description = "ML workspace ID"
  value       = azurerm_machine_learning_workspace.main.id
}

output "workspace_name" {
  description = "ML workspace name"
  value       = azurerm_machine_learning_workspace.main.name
}

output "workspace_discovery_url" {
  description = "ML workspace discovery URL"
  value       = azurerm_machine_learning_workspace.main.discovery_url
}

output "workspace_identity" {
  description = "ML workspace managed identity"
  value = {
    principal_id = azurerm_machine_learning_workspace.main.identity[0].principal_id
    tenant_id    = azurerm_machine_learning_workspace.main.identity[0].tenant_id
  }
}

# -----------------------------------------------------------------------------
# STORAGE OUTPUTS
# -----------------------------------------------------------------------------

output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.ml.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.ml.name
}

# -----------------------------------------------------------------------------
# KEY VAULT OUTPUTS
# -----------------------------------------------------------------------------

output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.ml.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.ml.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.ml.vault_uri
}

# -----------------------------------------------------------------------------
# APPLICATION INSIGHTS OUTPUTS
# -----------------------------------------------------------------------------

output "app_insights_id" {
  description = "Application Insights ID"
  value       = azurerm_application_insights.ml.id
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.ml.instrumentation_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.ml.connection_string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# CONTAINER REGISTRY OUTPUTS
# -----------------------------------------------------------------------------

output "container_registry_id" {
  description = "Container Registry ID"
  value       = var.enable_container_registry ? azurerm_container_registry.ml[0].id : null
}

output "container_registry_name" {
  description = "Container Registry name"
  value       = var.enable_container_registry ? azurerm_container_registry.ml[0].name : null
}

output "container_registry_login_server" {
  description = "Container Registry login server"
  value       = var.enable_container_registry ? azurerm_container_registry.ml[0].login_server : null
}

# -----------------------------------------------------------------------------
# COMPUTE CLUSTER OUTPUTS
# -----------------------------------------------------------------------------

output "compute_cluster_ids" {
  description = "Map of compute cluster IDs"
  value       = { for k, v in azurerm_machine_learning_compute_cluster.main : k => v.id }
}

output "compute_cluster_names" {
  description = "List of compute cluster names"
  value       = [for c in azurerm_machine_learning_compute_cluster.main : c.name]
}

# -----------------------------------------------------------------------------
# COMPUTE INSTANCE OUTPUTS
# -----------------------------------------------------------------------------

output "compute_instance_ids" {
  description = "Map of compute instance IDs"
  value       = { for k, v in azurerm_machine_learning_compute_instance.main : k => v.id }
}

output "compute_instance_names" {
  description = "List of compute instance names"
  value       = [for c in azurerm_machine_learning_compute_instance.main : c.name]
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT OUTPUTS
# -----------------------------------------------------------------------------

output "private_endpoint_workspace_id" {
  description = "Private endpoint ID for ML workspace"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.ml_workspace[0].id : null
}

output "private_endpoint_storage_id" {
  description = "Private endpoint ID for storage"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.storage[0].id : null
}

output "private_endpoint_acr_id" {
  description = "Private endpoint ID for ACR"
  value       = var.enable_container_registry && var.enable_private_endpoint ? azurerm_private_endpoint.acr[0].id : null
}