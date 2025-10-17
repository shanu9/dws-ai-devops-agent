# =============================================================================
# AZURE DATABASE MIGRATION SERVICE MODULE
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

locals {
  naming_prefix = "${var.customer_id}-${var.spoke_name}-${var.region_code}"
  dms_name = coalesce(
    var.dms_name,
    "dms-${local.naming_prefix}"
  )
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Database-Migration"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# DATABASE MIGRATION SERVICE
# -----------------------------------------------------------------------------

resource "azurerm_database_migration_service" "main" {
  name                = local.dms_name
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  sku_name            = var.sku_name
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DATABASE MIGRATION PROJECT
# -----------------------------------------------------------------------------

resource "azurerm_database_migration_project" "projects" {
  for_each = var.migration_projects
  
  name                = each.key
  service_name        = azurerm_database_migration_service.main.name
  resource_group_name = var.resource_group_name
  location            = var.region
  source_platform     = each.value.source_platform
  target_platform     = each.value.target_platform
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "dms" {
  count = var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${local.dms_name}"
  target_resource_id         = azurerm_database_migration_service.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}