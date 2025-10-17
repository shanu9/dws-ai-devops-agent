# =============================================================================
# DMS MODULE OUTPUTS
# =============================================================================

output "dms_id" {
  value = azurerm_database_migration_service.main.id
}

output "dms_name" {
  value = azurerm_database_migration_service.main.name
}

output "project_ids" {
  value = { for k, v in azurerm_database_migration_project.projects : k => v.id }
}

output "project_names" {
  value = [for p in azurerm_database_migration_project.projects : p.name]
}