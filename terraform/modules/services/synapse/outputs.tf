# =============================================================================
# SYNAPSE MODULE OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# WORKSPACE OUTPUTS
# -----------------------------------------------------------------------------

output "workspace_id" {
  description = "Synapse workspace ID"
  value       = azurerm_synapse_workspace.main.id
}

output "workspace_name" {
  description = "Synapse workspace name"
  value       = azurerm_synapse_workspace.main.name
}

output "workspace_endpoint" {
  description = "Synapse workspace development endpoint"
  value       = azurerm_synapse_workspace.main.connectivity_endpoints.dev
}

output "workspace_sql_endpoint" {
  description = "Synapse workspace SQL endpoint"
  value       = azurerm_synapse_workspace.main.connectivity_endpoints.sql
}

output "workspace_identity" {
  description = "Synapse workspace managed identity"
  value = {
    principal_id = azurerm_synapse_workspace.main.identity[0].principal_id
    tenant_id    = azurerm_synapse_workspace.main.identity[0].tenant_id
  }
}

# -----------------------------------------------------------------------------
# SQL POOL OUTPUTS
# -----------------------------------------------------------------------------

output "sql_pool_id" {
  description = "SQL pool ID"
  value       = var.enable_sql_pool ? azurerm_synapse_sql_pool.main[0].id : null
}

output "sql_pool_name" {
  description = "SQL pool name"
  value       = var.enable_sql_pool ? azurerm_synapse_sql_pool.main[0].name : null
}

# -----------------------------------------------------------------------------
# SPARK POOL OUTPUTS
# -----------------------------------------------------------------------------

output "spark_pool_id" {
  description = "Spark pool ID"
  value       = var.enable_spark_pool ? azurerm_synapse_spark_pool.main[0].id : null
}

output "spark_pool_name" {
  description = "Spark pool name"
  value       = var.enable_spark_pool ? azurerm_synapse_spark_pool.main[0].name : null
}

# -----------------------------------------------------------------------------
# STORAGE OUTPUTS
# -----------------------------------------------------------------------------

output "storage_account_id" {
  description = "Storage account ID for Synapse workspace"
  value       = azurerm_storage_account.synapse.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.synapse.name
}

output "filesystem_id" {
  description = "Data Lake Gen2 filesystem ID"
  value       = azurerm_storage_data_lake_gen2_filesystem.synapse.id
}

output "filesystem_name" {
  description = "Data Lake Gen2 filesystem name"
  value       = azurerm_storage_data_lake_gen2_filesystem.synapse.name
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT OUTPUTS
# -----------------------------------------------------------------------------

output "private_endpoint_sql_id" {
  description = "Private endpoint ID for SQL"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.synapse_sql[0].id : null
}

output "private_endpoint_dev_id" {
  description = "Private endpoint ID for Dev"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.synapse_dev[0].id : null
}

# -----------------------------------------------------------------------------
# CONNECTION STRINGS (Sensitive)
# -----------------------------------------------------------------------------

output "sql_connection_string" {
  description = "SQL connection string (serverless)"
  value       = "Server=tcp:${azurerm_synapse_workspace.main.name}.sql.azuresynapse.net,1433;Database=master;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive   = true
}

output "dedicated_sql_connection_string" {
  description = "Dedicated SQL pool connection string"
  value       = var.enable_sql_pool ? "Server=tcp:${azurerm_synapse_workspace.main.name}.sql.azuresynapse.net,1433;Database=${azurerm_synapse_sql_pool.main[0].name};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" : null
  sensitive   = true
}