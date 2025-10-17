# =============================================================================
# EVENT HUB MODULE OUTPUTS
# =============================================================================

output "eventhub_namespace_id" {
  value = azurerm_eventhub_namespace.main.id
}

output "eventhub_namespace_name" {
  value = azurerm_eventhub_namespace.main.name
}

output "eventhub_ids" {
  value = { for k, v in azurerm_eventhub.hubs : k => v.id }
}

output "eventhub_names" {
  value = [for h in azurerm_eventhub.hubs : h.name]
}

output "consumer_group_ids" {
  value = { for k, v in azurerm_eventhub_consumer_group.groups : k => v.id }
}

output "namespace_connection_string" {
  value     = azurerm_eventhub_namespace.main.default_primary_connection_string
  sensitive = true
}

output "identity" {
  value = {
    principal_id = azurerm_eventhub_namespace.main.identity[0].principal_id
    tenant_id    = azurerm_eventhub_namespace.main.identity[0].tenant_id
  }
}