# SQL Database Service Module

Azure SQL Database with private endpoint, TDE, threat detection, and backup.

## Usage
```hcl
module "sql" {
  source = "../../modules/services/sql"
  
  customer_id         = "abc"
  environment         = "prd"
  spoke_name          = "production"
  region              = "eastus"
  region_code         = "eus"
  resource_group_name = module.spoke.resource_group_name
  
  database_name          = "app-db"
  administrator_password = var.sql_password
  
  subnet_id           = module.spoke.private_subnet_id
  private_dns_zone_id = module.hub.private_dns_zone_ids["privatelink.database.windows.net"]
  
  log_analytics_workspace_id = module.management.central_workspace_id
  
  cost_center = "Production-DB"
  team        = "Data-Team"
}