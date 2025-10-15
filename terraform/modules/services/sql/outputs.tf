output "sql_server_id" {
  description = "SQL Server ID"
  value       = azurerm_mssql_server.main.id
}

output "sql_server_fqdn" {
  description = "SQL Server FQDN"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "database_id" {
  description = "Database ID"
  value       = azurerm_mssql_database.main.id
}

output "database_name" {
  description = "Database name"
  value       = azurerm_mssql_database.main.name
}

output "private_endpoint_ip" {
  description = "Private endpoint IP address"
  value       = azurerm_private_endpoint.sql.private_service_connection[0].private_ip_address
}

output "connection_string" {
  description = "SQL connection string (without password)"
  value       = "Server=${azurerm_mssql_server.main.fully_qualified_domain_name};Database=${azurerm_mssql_database.main.name};User Id=${var.administrator_login};"
  sensitive   = true
}