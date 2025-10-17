# =============================================================================
# COSMOS DB MODULE OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# ACCOUNT OUTPUTS
# -----------------------------------------------------------------------------

output "cosmos_account_id" {
  description = "Cosmos DB account ID"
  value       = azurerm_cosmosdb_account.main.id
}

output "cosmos_account_name" {
  description = "Cosmos DB account name"
  value       = azurerm_cosmosdb_account.main.name
}

output "cosmos_account_endpoint" {
  description = "Cosmos DB account endpoint"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "primary_key" {
  description = "Primary master key"
  value       = azurerm_cosmosdb_account.main.primary_key
  sensitive   = true
}

output "secondary_key" {
  description = "Secondary master key"
  value       = azurerm_cosmosdb_account.main.secondary_key
  sensitive   = true
}

output "primary_readonly_key" {
  description = "Primary readonly master key"
  value       = azurerm_cosmosdb_account.main.primary_readonly_key
  sensitive   = true
}

output "secondary_readonly_key" {
  description = "Secondary readonly master key"
  value       = azurerm_cosmosdb_account.main.secondary_readonly_key
  sensitive   = true
}

output "connection_strings" {
  description = "Cosmos DB connection strings"
  value       = azurerm_cosmosdb_account.main.connection_strings
  sensitive   = true
}

output "identity" {
  description = "Cosmos DB managed identity"
  value = {
    principal_id = azurerm_cosmosdb_account.main.identity[0].principal_id
    tenant_id    = azurerm_cosmosdb_account.main.identity[0].tenant_id
  }
}

# -----------------------------------------------------------------------------
# SQL API DATABASE OUTPUTS
# -----------------------------------------------------------------------------

output "sql_database_ids" {
  description = "Map of SQL database IDs"
  value       = { for k, v in azurerm_cosmosdb_sql_database.main : k => v.id }
}

output "sql_database_names" {
  description = "List of SQL database names"
  value       = [for db in azurerm_cosmosdb_sql_database.main : db.name]
}

output "sql_container_ids" {
  description = "Map of SQL container IDs"
  value       = { for k, v in azurerm_cosmosdb_sql_container.main : k => v.id }
}

output "sql_container_names" {
  description = "List of SQL container names"
  value       = [for c in azurerm_cosmosdb_sql_container.main : c.name]
}

# -----------------------------------------------------------------------------
# MONGODB API DATABASE OUTPUTS
# -----------------------------------------------------------------------------

output "mongo_database_ids" {
  description = "Map of MongoDB database IDs"
  value       = { for k, v in azurerm_cosmosdb_mongo_database.main : k => v.id }
}

output "mongo_database_names" {
  description = "List of MongoDB database names"
  value       = [for db in azurerm_cosmosdb_mongo_database.main : db.name]
}

output "mongo_collection_ids" {
  description = "Map of MongoDB collection IDs"
  value       = { for k, v in azurerm_cosmosdb_mongo_collection.main : k => v.id }
}

output "mongo_collection_names" {
  description = "List of MongoDB collection names"
  value       = [for c in azurerm_cosmosdb_mongo_collection.main : c.name]
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT OUTPUTS
# -----------------------------------------------------------------------------

output "private_endpoint_id" {
  description = "Private endpoint ID"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.cosmos[0].id : null
}

output "private_ip_address" {
  description = "Private IP address"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.cosmos[0].private_service_connection[0].private_ip_address : null
}

# -----------------------------------------------------------------------------
# CONNECTION INFO
# -----------------------------------------------------------------------------

output "connection_info" {
  description = "Connection information for applications"
  value = {
    endpoint          = azurerm_cosmosdb_account.main.endpoint
    account_name      = azurerm_cosmosdb_account.main.name
    api_kind          = var.cosmos_db_kind
    consistency_level = var.consistency_level
    locations         = azurerm_cosmosdb_account.main.read_endpoints
  }
}