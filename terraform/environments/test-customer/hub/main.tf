# =============================================================================
# HUB DEPLOYMENT - Calls Hub Module
# =============================================================================

# Data source: Get Management workspace
data "terraform_remote_state" "management" {
  backend = "azurerm"
  
  config = {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = var.management_state_key
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

  # Monitoring
  log_analytics_workspace_id = data.terraform_remote_state.management.outputs.central_workspace_id

  # High availability
  enable_zone_redundancy = true
  enable_ddos_protection = false

  # Tags
  tags = {
    Project     = "CAF-LZ"
    DeployedBy  = "Terraform"
    Criticality = "Critical"
  }
}

# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------

output "hub_vnet_id" {
  description = "Hub VNet ID for Spoke peering"
  value       = module.hub.vnet_id
}

output "hub_vnet_name" {
  description = "Hub VNet name"
  value       = module.hub.vnet_name
}

output "hub_resource_group_name" {
  description = "Hub resource group name"
  value       = module.hub.resource_group_name
}

output "hub_firewall_private_ip" {
  description = "Hub firewall private IP for routing"
  value       = module.hub.firewall_private_ip
}

output "hub_location" {
  description = "Hub location"
  value       = module.hub.resource_group_location
}

output "private_dns_zone_ids" {
  description = "Private DNS zone IDs for Spoke integration"
  value       = module.hub.private_dns_zone_ids
  sensitive   = true
}