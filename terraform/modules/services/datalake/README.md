# Storage Account (Data Lake Gen2) Module

Data Lake Storage with lifecycle management, versioning, and private endpoints.

## Usage
```hcl
module "storage" {
  source = "../../modules/services/storage"
  
  customer_id         = "abc"
  environment         = "prd"
  spoke_name          = "production"
  region              = "eastus"
  region_code         = "eus"
  resource_group_name = module.spoke.resource_group_name
  
  enable_hierarchical_namespace = true  # Data Lake Gen2
  account_replication_type      = "GRS"
  
  subnet_id = module.spoke.private_subnet_id
  
  private_dns_zone_ids = {
    blob = module.hub.private_dns_zone_ids["privatelink.blob.core.windows.net"]
    dfs  = module.hub.private_dns_zone_ids["privatelink.dfs.core.windows.net"]
    file = module.hub.private_dns_zone_ids["privatelink.file.core.windows.net"]
  }
  
  log_analytics_workspace_id = module.management.central_workspace_id
  
  cost_center = "Data-Platform"
  team        = "Data-Team"
}