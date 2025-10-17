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

# Temporarily disabled - deploy spoke base first
/*
module "sql" {
  ...
}

module "keyvault" {
  ...
}

module "storage" {
  ...
}

module "datafactory" {
  ...
}
*/