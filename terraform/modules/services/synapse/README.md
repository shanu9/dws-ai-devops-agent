# Azure Synapse Analytics Module

Enterprise data warehouse with integrated Spark analytics, pipelines, and SQL pools.

## Features

- ✅ Synapse Workspace with managed VNet
- ✅ Dedicated SQL Pool (optional - high cost)
- ✅ Serverless SQL Pool (included)
- ✅ Apache Spark Pool with auto-scale
- ✅ Data Lake Gen2 Storage
- ✅ Private Endpoints
- ✅ Azure AD authentication
- ✅ Cost optimization (auto-pause, auto-scale)
- ✅ Diagnostic settings

## Usage
```hcl
module "synapse" {
  source = "../../modules/services/synapse"
  
  customer_id         = "test"
  environment         = "prd"
  spoke_name          = "production"
  region              = "eastus"
  region_code         = "eus"
  resource_group_name = module.spoke.resource_group_name
  
  # Authentication
  sql_admin_username = "sqladmin"
  sql_admin_password = var.synapse_password # From Key Vault
  
  # Spark Pool (Recommended)
  enable_spark_pool       = true
  spark_node_size         = "Small"
  spark_node_count_min    = 3
  spark_node_count_max    = 10
  enable_spark_autoscale  = true
  spark_auto_pause_delay  = 15
  
  # SQL Pool (Optional - Expensive!)
  enable_sql_pool            = false # Start with serverless
  sql_pool_sku               = "DW100c"
  sql_pool_auto_pause_delay  = 60
  
  # Private Endpoint
  enable_private_endpoint  = true
  subnet_id                = module.spoke.private_subnet_id
  private_dns_zone_id_sql  = data.terraform_remote_state.hub.outputs.private_dns_zone_ids["synapse"]
  
  # Monitoring
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.central_workspace_id
  
  # Cost allocation
  cost_center = "Data-Warehouse"
  team        = "Data-Platform"
}
```

## Cost Estimates

| Component | Configuration | Monthly Cost |
|-----------|--------------|--------------|
| Workspace | Included | $0 |
| Serverless SQL | Pay-per-query | $5/TB |
| Spark Pool (Small) | 3 nodes, auto-pause | $300-800 |
| Dedicated SQL (DW100c) | Auto-pause 60min | $1,200-2,400 |
| Storage (1TB) | GRS | $50 |

**Total**: $355 - $3,250/month depending on configuration

## Best Practices

1. **Start with Serverless**: Use serverless SQL first, add dedicated pools only when needed
2. **Enable Auto-Pause**: Save 70% costs by pausing when idle
3. **Use Spark Autoscale**: Scale based on workload
4. **Private Endpoints Only**: Disable public access
5. **Managed VNet**: Keep data within Azure backbone

## Outputs
```hcl
workspace_id              # For pipeline integration
workspace_sql_endpoint    # For SQL connections
spark_pool_name           # For Spark jobs
storage_account_name      # For data ingestion
```