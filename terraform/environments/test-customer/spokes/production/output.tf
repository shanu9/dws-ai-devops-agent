# =============================================================================
# SPOKE OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# SPOKE BASE OUTPUTS
# -----------------------------------------------------------------------------

output "spoke_vnet_id" {
  description = "Spoke VNet ID"
  value       = module.spoke.vnet_id
}

output "spoke_vnet_name" {
  description = "Spoke VNet name"
  value       = module.spoke.vnet_name
}

output "resource_group_name" {
  description = "Spoke resource group name"
  value       = module.spoke.resource_group_name
}

output "database_subnet_id" {
  description = "Database subnet ID"
  value       = module.spoke.database_subnet_id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = module.spoke.private_subnet_id
}

output "application_subnet_id" {
  description = "Application subnet ID"
  value       = module.spoke.application_subnet_id
}


# -----------------------------------------------------------------------------
# KEY VAULT OUTPUTS
# -----------------------------------------------------------------------------

output "keyvault_id" {
  description = "Key Vault ID"
  value       = var.enable_keyvault ? module.keyvault[0].keyvault_id : null
}

output "keyvault_uri" {
  description = "Key Vault URI"
  value       = var.enable_keyvault ? module.keyvault[0].keyvault_uri : null
}

output "keyvault_name" {
  description = "Key Vault name"
  value       = var.enable_keyvault ? module.keyvault[0].keyvault_name : null
}

# Storage outputs
output "storage_account_id" {
  value = var.enable_storage ? module.datalake[0].storage_account_id : null
}

output "storage_account_name" {
  value = var.enable_storage ? module.datalake[0].storage_account_name : null
}

output "storage_primary_blob_endpoint" {
  value = var.enable_storage ? module.datalake[0].primary_blob_endpoint : null
}

output "storage_primary_dfs_endpoint" {
  value = var.enable_storage ? module.datalake[0].primary_dfs_endpoint : null
}
# -----------------------------------------------------------------------------
# DATA FACTORY OUTPUTS
# -----------------------------------------------------------------------------

output "datafactory_id" {
  description = "Data Factory ID"
  value       = var.enable_datafactory ? module.datafactory[0].data_factory_id : null
}

output "datafactory_name" {
  description = "Data Factory name"
  value       = var.enable_datafactory ? module.datafactory[0].data_factory_name : null
}


# -----------------------------------------------------------------------------
# DEPLOYMENT SUMMARY
# -----------------------------------------------------------------------------

output "deployment_summary" {
  description = "Deployment summary"
  value = <<-EOT
    ============================================================
    SPOKE DEPLOYMENT COMPLETE
    ============================================================
    Customer:     ${var.customer_id}
    Environment:  ${var.environment}
    Spoke:        ${var.spoke_name}
    Region:       ${var.region}
    
    Network:
      VNet:       ${module.spoke.vnet_name}
      CIDR:       ${var.spoke_vnet_cidr}
    
    Services Deployed:
      SQL:         ${var.enable_sql}
      KeyVault:    ${var.enable_keyvault}
      Storage:     ${var.enable_storage}
      DataFactory: ${var.enable_datafactory}
      Synapse:     ${var.enable_synapse}
      CosmosDB:    ${var.enable_cosmosdb}
      Azure ML:    ${var.enable_ml}
      Cognitive Search: ${var.enable_cognitive_search}
      Functions:   ${var.enable_functions}
      EventHub:    ${var.enable_eventhub}
      Stream Analytics: ${var.enable_stream_analytics}
      Purview:     ${var.enable_purview}
    
    Cost Center:  ${var.cost_center}
    Team:         ${var.team}
    ============================================================
  EOT
}