# =============================================================================
# AZURE COGNITIVE SEARCH MODULE
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
  search_service_name = coalesce(
    var.search_service_name,
    "srch-${local.naming_prefix}"
  )
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Cognitive-Search"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# COGNITIVE SEARCH SERVICE
# -----------------------------------------------------------------------------

resource "azurerm_search_service" "main" {
  name                = local.search_service_name
  resource_group_name = var.resource_group_name
  location            = var.region
  sku                 = var.search_sku
  
  # Replica and partition count (determines capacity and cost)
  replica_count   = var.replica_count
  partition_count = var.partition_count
  
  # Public network access
  public_network_access_enabled = var.public_network_access_enabled
  
  # Customer-managed key encryption
  dynamic "identity" {
    for_each = var.enable_customer_managed_key ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }
  
  # Allowed IP ranges (if public access enabled)
  allowed_ip_ranges = var.public_network_access_enabled ? var.allowed_ip_ranges : []
  
  # Semantic search (premium feature)
  semantic_search_sku = var.enable_semantic_search ? var.semantic_search_sku : "disabled"
  
  # Local authentication (API keys)
  local_authentication_enabled = var.enable_local_authentication
  
  # Authentication using Azure AD
  authentication_failure_mode = var.authentication_failure_mode
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "search" {
  count = var.enable_private_endpoint ? 1 : 0
  
  name                = "pe-${local.search_service_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.search_service_name}"
    private_connection_resource_id = azurerm_search_service.main.id
    is_manual_connection           = false
    subresource_names              = ["searchService"]
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "pdz-group-search"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SHARED PRIVATE LINK RESOURCES (For indexers to access private data sources)
# -----------------------------------------------------------------------------

resource "azurerm_search_shared_private_link_service" "data_sources" {
  for_each = var.private_link_resources
  
  name               = "spl-${each.key}"
  search_service_id  = azurerm_search_service.main.id
  subresource_name   = each.value.subresource_name
  target_resource_id = each.value.resource_id
  request_message    = each.value.request_message
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "search" {
  count = var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${local.search_service_name}"
  target_resource_id         = azurerm_search_service.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "OperationLogs"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}