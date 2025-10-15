# Key Vault Service Module

Secure key and secret management with private endpoint.

## Usage
```hcl
module "keyvault" {
  source = "../../modules/services/keyvault"
  
  customer_id         = "abc"
  environment         = "prd"
  spoke_name          = "production"
  region              = "eastus"
  region_code         = "eus"
  resource_group_name = module.spoke.resource_group_name
  
  subnet_id           = module.spoke.private_subnet_id
  private_dns_zone_id = module.hub.private_dns_zone_ids["privatelink.vaultcore.azure.net"]
  
  log_analytics_workspace_id = module.management.central_workspace_id
  
  enable_rbac_authorization = true
  purge_protection_enabled  = true
  
  cost_center = "Security"
  team        = "Platform-Team"
}