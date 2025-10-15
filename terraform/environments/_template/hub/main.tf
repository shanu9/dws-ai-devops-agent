# =============================================================================
# HUB DEPLOYMENT - Calls Hub Module
# =============================================================================

# First, deploy Management (Log Analytics) as Hub needs workspace_id
# Then deploy Hub

# Data source: Get Management workspace (deployed separately)
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
# HUB MODULE
# -----------------------------------------------------------------------------

module "hub" {
  source = "../../../modules/hub"
  
  # Identity
  customer_id = var.customer_id
  environment = var.environment
  region      = var.region
  region_code = var.region_code
  
  # Network
  hub_vnet_address_space = [var.hub_vnet_cidr]
  
  # Firewall
  firewall_sku_tier          = var.firewall_sku
  firewall_threat_intel_mode = "Alert"
  enable_firewall_dns_proxy  = true
  firewall_availability_zones = ["1", "2", "3"]
  
  # Bastion
  enable_bastion      = var.enable_bastion
  bastion_sku         = "Basic"
  bastion_scale_units = 2
  
  # VPN Gateway
  enable_vpn_gateway     = var.enable_vpn_gateway
  vpn_gateway_sku        = "VpnGw1"
  vpn_gateway_generation = "Generation2"
  
  # Private DNS
  enable_private_dns_zones = true
  # Uses default 20+ DNS zones
  
  # Monitoring (from Management module)
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.central_workspace_id
  
  # High availability
  enable_zone_redundancy = true
  enable_ddos_protection = false
  
  # Tags
  tags = {
    Project     = "CAF-LZ"
    DeployedBy  = "YourCompany-SaaS"
    Criticality = "Critical"
  }
}

# -----------------------------------------------------------------------------
# OUTPUTS (for Spoke consumption)
# -----------------------------------------------------------------------------

output "hub_vnet_id" {
  value = module.hub.vnet_id
}

output "hub_vnet_name" {
  value = module.hub.vnet_name
}

output "hub_resource_group_name" {
  value = module.hub.resource_group_name
}

output "hub_firewall_private_ip" {
  value = module.hub.firewall_private_ip
}

output "hub_location" {
  value = module.hub.resource_group_location
}

output "private_dns_zone_ids" {
  value     = module.hub.private_dns_zone_ids
  sensitive = true
}