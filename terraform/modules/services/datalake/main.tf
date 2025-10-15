# =============================================================================
# AZURE STORAGE ACCOUNT (DATA LAKE GEN2) MODULE
# =============================================================================

locals {
  naming_prefix = "${var.customer_id}${var.spoke_name}${var.region_code}"
  # Storage account: 3-24 chars, lowercase alphanumeric only
  storage_account_name = coalesce(
    var.storage_account_name,
    substr(replace(lower("st${local.naming_prefix}"), "-", ""), 0, 24)
  )
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Storage-DataLake"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# STORAGE ACCOUNT
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.region
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier
  
  # Data Lake Gen2 (ADLS)
  is_hns_enabled           = var.enable_hierarchical_namespace
  
  # Security
  enable_https_traffic_only       = var.enable_https_traffic_only
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  shared_access_key_enabled       = var.shared_access_key_enabled
  public_network_access_enabled   = var.public_network_access_enabled
  default_to_oauth_authentication = var.default_to_oauth_authentication
  
  # Network rules
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
  
  # Blob properties
  blob_properties {
    versioning_enabled  = var.enable_versioning
    change_feed_enabled = var.change_feed_enabled
    
    delete_retention_policy {
      days = var.delete_retention_days
    }
    
    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# BLOB CONTAINERS
# -----------------------------------------------------------------------------

resource "azurerm_storage_container" "containers" {
  for_each = var.containers
  
  name                  = each.key
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = each.value.container_access_type
}

# -----------------------------------------------------------------------------
# LIFECYCLE MANAGEMENT POLICY
# -----------------------------------------------------------------------------

resource "azurerm_storage_management_policy" "lifecycle" {
  count = var.enable_lifecycle_management ? 1 : 0
  
  storage_account_id = azurerm_storage_account.main.id
  
  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.key
      enabled = rule.value.enabled
      
      filters {
        blob_types   = rule.value.blob_types
        prefix_match = rule.value.prefix_match
      }
      
      actions {
        base_blob {
          tier_to_cool_after_days_since_modification_greater_than    = rule.value.tier_to_cool_after_days
          tier_to_archive_after_days_since_modification_greater_than = rule.value.tier_to_archive_after_days
          delete_after_days_since_modification_greater_than          = rule.value.delete_after_days
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINTS
# -----------------------------------------------------------------------------

# Blob private endpoint
resource "azurerm_private_endpoint" "blob" {
  count = var.enable_blob_private_endpoint ? 1 : 0
  
  name                = "pe-${local.storage_account_name}-blob"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.storage_account_name}-blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_ids["blob"]]
  }
  
  tags = local.common_tags
}

# DFS (Data Lake Gen2) private endpoint
resource "azurerm_private_endpoint" "dfs" {
  count = var.enable_dfs_private_endpoint && var.enable_hierarchical_namespace ? 1 : 0
  
  name                = "pe-${local.storage_account_name}-dfs"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.storage_account_name}-dfs"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["dfs"]
  }
  
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_ids["dfs"]]
  }
  
  tags = local.common_tags
}

# File share private endpoint
resource "azurerm_private_endpoint" "file" {
  count = var.enable_file_private_endpoint ? 1 : 0
  
  name                = "pe-${local.storage_account_name}-file"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.storage_account_name}-file"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
  
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_ids["file"]]
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "diag-${local.storage_account_name}"
  target_resource_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  metric {
    category = "Transaction"
  }
}

resource "azurerm_monitor_diagnostic_setting" "blob" {
  name                       = "diag-${local.storage_account_name}-blob"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default/"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "StorageRead"
  }
  
  enabled_log {
    category = "StorageWrite"
  }
  
  enabled_log {
    category = "StorageDelete"
  }
  
  metric {
    category = "Transaction"
  }
}