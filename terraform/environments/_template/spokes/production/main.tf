# =============================================================================
# SPOKE + SERVICES DEPLOYMENT
# =============================================================================
# This shows how Spoke and Services work together

# Data sources: Get Hub and Management outputs
data "terraform_remote_state" "hub" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate${var.customer_id}"
    container_name       = "tfstate"
    key                  = "${var.customer_id}/hub.tfstate"
  }
}

data "terraform_remote_state" "management" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate${var.customer_id}"
    container_name       = "tfstate"
    key                  = "${var.customer_id}/management.tfstate"
  }
}

# -----------------------------------------------------------------------------
# SPOKE-BASE MODULE
# -----------------------------------------------------------------------------

module "spoke" {
  source = "../../../../modules/spoke-base"
  
  customer_id = var.customer_id
  environment = var.environment
  spoke_name  = var.spoke_name
  region      = var.region
  region_code = var.region_code
  
  spoke_vnet_address_space = [var.spoke_vnet_cidr]
  
  # Hub connectivity (from Hub module outputs)
  hub_vnet_id             = data.terraform_remote_state.hub.outputs.hub_vnet_id
  hub_vnet_name           = data.terraform_remote_state.hub.outputs.hub_vnet_name
  hub_resource_group_name = data.terraform_remote_state.hub.outputs.hub_resource_group_name
  hub_firewall_private_ip = data.terraform_remote_state.hub.outputs.hub_firewall_private_ip
  hub_location            = data.terraform_remote_state.hub.outputs.hub_location
  
  # Private DNS (from Hub)
  private_dns_zone_ids        = data.terraform_remote_state.hub.outputs.private_dns_zone_ids
  enable_private_dns_integration = true
  
  # Monitoring (from Management)
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.central_workspace_id
  
  # Cost allocation
  cost_center        = "Production-Workloads"
  team               = "TeamA-Operations"
  chargeback_enabled = true
  
  tags = {
    Workload = "Production"
  }
}

# =============================================================================
# SERVICES (Conditional - based on customer selection)
# =============================================================================

# -----------------------------------------------------------------------------
# SQL DATABASE (if enabled)
# -----------------------------------------------------------------------------

module "sql" {
  count  = var.enable_sql ? 1 : 0
  source = "../../../../modules/services/sql"
  
  customer_id         = var.customer_id
  environment         = var.environment
  spoke_name          = var.spoke_name
  region              = var.region
  region_code         = var.region_code
  resource_group_name = module.spoke.resource_group_name
  
  database_name          = var.sql_database_name
  administrator_password = var.sql_admin_password
  
  sku_name             = "GP_S_Gen5_2"  # Serverless
  min_capacity         = 0.5
  auto_pause_delay_in_minutes = 60
  
  subnet_id           = module.spoke.private_subnet_id
  private_dns_zone_id = data.terraform_remote_state.hub.outputs.private_dns_zone_ids["privatelink.database.windows.net"]
  
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.central_workspace_id
  
  cost_center = "Production-Database"
  team        = "Data-Team"
}

# -----------------------------------------------------------------------------
# KEY VAULT (if enabled)
# -----------------------------------------------------------------------------

module "keyvault" {
  count  = var.enable_keyvault ? 1 : 0
  source = "../../../../modules/services/keyvault"
  
  customer_id         = var.customer_id
  environment         = var.environment
  spoke_name          = var.spoke_name
  region              = var.region
  region_code         = var.region_code
  resource_group_name = module.spoke.resource_group_name
  
  enable_rbac_authorization = true
  purge_protection_enabled  = true
  
  subnet_id           = module.spoke.private_subnet_id
  private_dns_zone_id = data.terraform_remote_state.hub.outputs.private_dns_zone_ids["privatelink.vaultcore.azure.net"]
  
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.central_workspace_id
  
  cost_center = "Security"
  team        = "Platform-Team"
}

# -----------------------------------------------------------------------------
# STORAGE ACCOUNT (Data Lake if enabled)
# -----------------------------------------------------------------------------

module "storage" {
  count  = var.enable_storage ? 1 : 0
  source = "../../../../modules/services/storage"
  
  customer_id         = var.customer_id
  environment         = var.environment
  spoke_name          = var.spoke_name
  region              = var.region
  region_code         = var.region_code
  resource_group_name = module.spoke.resource_group_name
  
  enable_hierarchical_namespace = true  # Data Lake Gen2
  account_replication_type      = "GRS"
  
  subnet_id = module.spoke.private_subnet_id
  
  private_dns_zone_ids = {
    blob = data.terraform_remote_state.hub.outputs.private_dns_zone_ids["privatelink.blob.core.windows.net"]
    dfs  = data.terraform_remote_state.hub.outputs.private_dns_zone_ids["privatelink.dfs.core.windows.net"]
    file = data.terraform_remote_state.hub.outputs.private_dns_zone_ids["privatelink.file.core.windows.net"]
  }
  
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.central_workspace_id
  
  cost_center = "Data-Platform"
  team        = "Data-Team"
}

# -----------------------------------------------------------------------------
# DATA FACTORY (if enabled)
# -----------------------------------------------------------------------------

module "datafactory" {
  count  = var.enable_datafactory ? 1 : 0
  source = "../../../../modules/services/datafactory"
  
  customer_id         = var.customer_id
  environment         = var.environment
  spoke_name          = var.spoke_name
  region              = var.region
  region_code         = var.region_code
  resource_group_name = module.spoke.resource_group_name
  
  managed_virtual_network_enabled = true
  
  subnet_id           = module.spoke.private_subnet_id
  private_dns_zone_id = data.terraform_remote_state.hub.outputs.private_dns_zone_ids["privatelink.datafactory.azure.net"]
  
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.central_workspace_id
  
  cost_center = "Data-Engineering"
  team        = "Data-Team"
}

# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------

output "spoke_vnet_id" {
  value = module.spoke.vnet_id
}

output "sql_server_fqdn" {
  value = var.enable_sql ? module.sql[0].sql_server_fqdn : null
}

output "keyvault_uri" {
  value = var.enable_keyvault ? module.keyvault[0].keyvault_uri : null
}

output "storage_account_name" {
  value = var.enable_storage ? module.storage[0].storage_account_name : null
}

output "datafactory_name" {
  value = var.enable_datafactory ? module.datafactory[0].data_factory_name : null
}