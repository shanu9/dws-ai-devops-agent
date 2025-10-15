# Data Factory Module

Azure Data Factory with managed VNet, private endpoint, and integration runtime.

## Usage
```hcl
module "datafactory" {
  source = "../../modules/services/datafactory"
  
  customer_id         = "abc"
  environment         = "prd"
  spoke_name          = "production"
  region              = "eastus"
  region_code         = "eus"
  resource_group_name = module.spoke.resource_group_name
  
  managed_virtual_network_enabled = true
  
  subnet_id           = module.spoke.private_subnet_id
  private_dns_zone_id = module.hub.private_dns_zone_ids["privatelink.datafactory.azure.net"]
  
  log_analytics_workspace_id = module.management.central_workspace_id
  
  cost_center = "Data-Engineering"
  team        = "Data-Team"
}