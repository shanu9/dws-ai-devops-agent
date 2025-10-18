# DATA SOURCES
data "terraform_remote_state" "hub" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate78a1dec0"
    container_name       = "tfstate"
    key                  = "hub.tfstate"
  }
}

data "terraform_remote_state" "management" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate78a1dec0"
    container_name       = "tfstate"
    key                  = "management.tfstate"
  }
}

# SPOKE BASE
module "spoke" {
  source = "../../../../modules/spoke-base"
  
  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub  
  }
  
  customer_id = var.customer_id
  environment = var.environment
  spoke_name  = var.spoke_name
  region      = var.region
  region_code = var.region_code
  
  spoke_vnet_address_space = [var.spoke_vnet_cidr]
  
  hub_vnet_id             = data.terraform_remote_state.hub.outputs.hub_vnet_id
  hub_vnet_name           = data.terraform_remote_state.hub.outputs.hub_vnet_name
  hub_resource_group_name = data.terraform_remote_state.hub.outputs.hub_resource_group_name
  hub_firewall_private_ip = data.terraform_remote_state.hub.outputs.hub_firewall_private_ip
  hub_location            = data.terraform_remote_state.hub.outputs.hub_location
  
  private_dns_zone_ids           = data.terraform_remote_state.hub.outputs.private_dns_zone_ids
  enable_private_dns_integration = true
  
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.central_workspace_id
  
  cost_center        = var.cost_center
  team               = var.team
  chargeback_enabled = true
  
  tags = var.tags
}
# KEY VAULT
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
  purge_protection_enabled  = var.keyvault_purge_protection
  
  subnet_id           = module.spoke.private_subnet_id
  private_dns_zone_id = data.terraform_remote_state.hub.outputs.private_dns_zone_ids["key_vault"]  # ✅ Fixed
  
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.central_workspace_id
  
  cost_center = var.cost_center
  team        = var.team
}

# DATA LAKE GEN2
module "datalake" {
  count  = var.enable_storage ? 1 : 0
  source = "../../../../modules/services/datalake"
  
  customer_id         = var.customer_id
  environment         = var.environment
  spoke_name          = var.spoke_name
  region              = var.region
  region_code         = var.region_code
  resource_group_name = module.spoke.resource_group_name
  
  enable_hierarchical_namespace = var.storage_enable_data_lake
  account_replication_type      = var.storage_replication_type
  
  subnet_id = module.spoke.private_subnet_id
  private_dns_zone_ids = {
    blob = data.terraform_remote_state.hub.outputs.private_dns_zone_ids["blob_storage"]  # ✅ Fixed
    dfs  = data.terraform_remote_state.hub.outputs.private_dns_zone_ids["blob_storage"]  # ✅ Fixed (uses same zone)
    file = data.terraform_remote_state.hub.outputs.private_dns_zone_ids["file_storage"]  # ✅ Fixed
  }
  
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.central_workspace_id
  
  cost_center = var.cost_center
  team        = var.team
}

# DATA FACTORY
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
  private_dns_zone_id = null  # ✅ DataFactory DNS zone not in Hub, set to null
  
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.central_workspace_id
  
  cost_center = var.cost_center
  team        = var.team
}