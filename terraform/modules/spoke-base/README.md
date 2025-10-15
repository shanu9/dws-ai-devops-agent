# Spoke-Base Module

Deploys Spoke VNet infrastructure for workload hosting with Hub connectivity.

## Components

- VNet with 3 subnets (Database/Private/Application)
- NSGs per subnet
- Route tables (traffic via Firewall)
- VNet peering to Hub
- Private DNS integration

## Usage
```hcl
module "spoke" {
  source = "../../modules/spoke-base"
  
  customer_id = "abc"
  environment = "prd"
  spoke_name  = "production"
  region      = "eastus"
  region_code = "eus"
  
  spoke_vnet_address_space = ["10.2.0.0/16"]
  
  # Hub connectivity
  hub_vnet_id             = module.hub.vnet_id
  hub_vnet_name           = module.hub.vnet_name
  hub_resource_group_name = module.hub.resource_group_name
  hub_firewall_private_ip = module.hub.firewall_private_ip
  hub_location            = module.hub.resource_group_location
  
  # Private DNS
  private_dns_zone_ids = module.hub.private_dns_zone_ids
  
  # Monitoring
  log_analytics_workspace_id = module.management.central_workspace_id
  
  # Cost allocation
  cost_center = "Production-Workloads"
  team        = "TeamA-Operations"
}