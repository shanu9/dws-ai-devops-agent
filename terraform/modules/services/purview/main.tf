# =============================================================================
# AZURE PURVIEW MODULE
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
  purview_account_name = coalesce(
    var.purview_account_name,
    "purview-${replace(local.naming_prefix, "-", "")}"
  )
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Purview"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# PURVIEW ACCOUNT
# -----------------------------------------------------------------------------

resource "azurerm_purview_account" "main" {
  name                = local.purview_account_name
  resource_group_name = var.resource_group_name
  location            = var.region
  
  # Identity
  identity {
    type = "SystemAssigned"
  }
  
  # Public network access
  public_network_enabled = var.public_network_access_enabled
  
  # Managed resources
  managed_resource_group_name = var.managed_resource_group_name != null ? var.managed_resource_group_name : "${var.resource_group_name}-purview-managed"
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINTS
# -----------------------------------------------------------------------------

# Private endpoint for account
resource "azurerm_private_endpoint" "account" {
  count = var.enable_private_endpoint ? 1 : 0
  
  name                = "pe-${local.purview_account_name}-account"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.purview_account_name}-account"
    private_connection_resource_id = azurerm_purview_account.main.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id_account != null ? [1] : []
    content {
      name                 = "pdz-group-account"
      private_dns_zone_ids = [var.private_dns_zone_id_account]
    }
  }
  
  tags = local.common_tags
}

# Private endpoint for portal
resource "azurerm_private_endpoint" "portal" {
  count = var.enable_private_endpoint ? 1 : 0
  
  name                = "pe-${local.purview_account_name}-portal"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.purview_account_name}-portal"
    private_connection_resource_id = azurerm_purview_account.main.id
    is_manual_connection           = false
    subresource_names              = ["portal"]
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id_portal != null ? [1] : []
    content {
      name                 = "pdz-group-portal"
      private_dns_zone_ids = [var.private_dns_zone_id_portal]
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# RBAC ASSIGNMENTS FOR DATA SOURCES
# -----------------------------------------------------------------------------

# Grant Purview access to storage accounts
resource "azurerm_role_assignment" "storage_blob_reader" {
  for_each = toset(var.storage_account_ids)
  
  scope                = each.value
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_purview_account.main.identity[0].principal_id
}

# Grant Purview access to SQL databases
resource "azurerm_role_assignment" "sql_reader" {
  for_each = toset(var.sql_server_ids)
  
  scope                = each.value
  role_definition_name = "Reader"
  principal_id         = azurerm_purview_account.main.identity[0].principal_id
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "purview" {
  count = var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${local.purview_account_name}"
  target_resource_id         = azurerm_purview_account.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "ScanStatusLogEvent"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}