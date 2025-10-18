# =============================================================================
# AZURE SYNAPSE ANALYTICS MODULE
# =============================================================================
# Purpose: Enterprise data warehouse with integrated analytics
# Components: Synapse workspace, SQL pools, Spark pools, pipelines
# Best Practices: Managed VNet, private endpoints, cost optimization
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# -----------------------------------------------------------------------------
# LOCAL VARIABLES
# -----------------------------------------------------------------------------

locals {
  naming_prefix = "${var.customer_id}-${var.spoke_name}-${var.region_code}"
  
  synapse_workspace_name = coalesce(
    var.synapse_workspace_name,
    "synapse-${local.naming_prefix}"
  )
  
  sql_pool_name = coalesce(
    var.sql_pool_name,
    "sqlpool${replace(var.customer_id, "-", "")}"
  )
  
  spark_pool_name = coalesce(
    var.spark_pool_name,
    "sparkpool${replace(var.customer_id, "-", "")}"
  )
  
  storage_account_name = "synapse${replace(local.naming_prefix, "-", "")}${random_string.storage_suffix.result}"
  filesystem_name      = "synapsefs"
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Synapse-Analytics"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# RANDOM SUFFIX FOR STORAGE
# -----------------------------------------------------------------------------

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# -----------------------------------------------------------------------------
# STORAGE ACCOUNT FOR SYNAPSE WORKSPACE (Required)
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "synapse" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type
  account_kind             = "StorageV2"
  is_hns_enabled           = true # Required for Data Lake Gen2
  
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  # Network rules
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
  
  tags = local.common_tags
}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
  name               = local.filesystem_name
  storage_account_id = azurerm_storage_account.synapse.id
}

# -----------------------------------------------------------------------------
# SYNAPSE WORKSPACE
# -----------------------------------------------------------------------------

resource "azurerm_synapse_workspace" "main" {
  name                                 = local.synapse_workspace_name
  resource_group_name                  = var.resource_group_name
  location                             = var.region
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse.id
  sql_administrator_login              = var.sql_admin_username
  sql_administrator_login_password     = var.sql_admin_password
  
  # Managed Virtual Network (Best Practice)
  managed_virtual_network_enabled      = var.enable_managed_vnet
  managed_resource_group_name          = "${var.resource_group_name}-synapse-managed"
  public_network_access_enabled        = var.public_network_access_enabled
  data_exfiltration_protection_enabled = var.enable_data_exfiltration_protection
  
  # Azure AD Authentication
  dynamic "aad_admin" {
    for_each = var.aad_admin != null ? [var.aad_admin] : []
    content {
      login     = aad_admin.value.login
      object_id = aad_admin.value.object_id
      tenant_id = aad_admin.value.tenant_id
    }
  }
  
  # Identity
  identity {
    type = "SystemAssigned"
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SYNAPSE SQL POOL (Dedicated - Optional, High Cost)
# -----------------------------------------------------------------------------
resource "azurerm_synapse_sql_pool" "main" {
  count = var.enable_sql_pool ? 1 : 0
  
  name                 = local.sql_pool_name
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  sku_name             = var.sql_pool_sku
  create_mode          = "Default"
  
  # Note: Auto-pause and auto-scale are managed via Azure portal or API
  # The Terraform provider v3.x doesn't support these blocks
  # Configure via Azure Policy or ARM templates if needed
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SYNAPSE SPARK POOL (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_synapse_spark_pool" "main" {
  count = var.enable_spark_pool ? 1 : 0
  
  name                 = local.spark_pool_name
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  node_size_family     = "MemoryOptimized"
  node_size            = var.spark_node_size
  node_count           = var.spark_node_count_min
  
  # Auto-scale
  dynamic "auto_scale" {
    for_each = var.enable_spark_autoscale ? [1] : []
    content {
      max_node_count = var.spark_node_count_max
      min_node_count = var.spark_node_count_min
    }
  }
  
  # Auto-pause (Cost optimization)
  auto_pause {
    delay_in_minutes = var.spark_auto_pause_delay
  }
  
  spark_version = var.spark_version
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT (Best Practice)
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "synapse_sql" {
  count = var.enable_private_endpoint ? 1 : 0
  
  name                = "pe-${local.synapse_workspace_name}-sql"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.synapse_workspace_name}-sql"
    private_connection_resource_id = azurerm_synapse_workspace.main.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id_sql != null ? [1] : []
    content {
      name                 = "pdz-group-sql"
      private_dns_zone_ids = [var.private_dns_zone_id_sql]
    }
  }
  
  tags = local.common_tags
}

resource "azurerm_private_endpoint" "synapse_dev" {
  count = var.enable_private_endpoint ? 1 : 0
  
  name                = "pe-${local.synapse_workspace_name}-dev"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.synapse_workspace_name}-dev"
    private_connection_resource_id = azurerm_synapse_workspace.main.id
    is_manual_connection           = false
    subresource_names              = ["Dev"]
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id_dev != null ? [1] : []
    content {
      name                 = "pdz-group-dev"
      private_dns_zone_ids = [var.private_dns_zone_id_dev]
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# FIREWALL RULES (If public access enabled)
# -----------------------------------------------------------------------------

resource "azurerm_synapse_firewall_rule" "allow_azure" {
  count = var.public_network_access_enabled ? 1 : 0
  
  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
}

resource "azurerm_synapse_firewall_rule" "custom" {
  for_each = var.public_network_access_enabled ? var.firewall_rules : {}
  
  name                 = each.key
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  start_ip_address     = each.value.start_ip
  end_ip_address       = each.value.end_ip
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "synapse" {
  count = var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${local.synapse_workspace_name}"
  target_resource_id         = azurerm_synapse_workspace.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "SynapseRbacOperations"
  }
  
  enabled_log {
    category = "GatewayApiRequests"
  }
  
  enabled_log {
    category = "SQLSecurityAuditEvents"
  }
  
  enabled_log {
    category = "BuiltinSqlReqsEnded"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "sql_pool" {
  count = var.enable_sql_pool && var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${local.sql_pool_name}"
  target_resource_id         = azurerm_synapse_sql_pool.main[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "SqlRequests"
  }
  
  enabled_log {
    category = "RequestSteps"
  }
  
  enabled_log {
    category = "DmsWorkers"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# -----------------------------------------------------------------------------
# RBAC: Grant Synapse access to storage
# -----------------------------------------------------------------------------

resource "azurerm_role_assignment" "synapse_storage" {
  scope                = azurerm_storage_account.synapse.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.main.identity[0].principal_id
}