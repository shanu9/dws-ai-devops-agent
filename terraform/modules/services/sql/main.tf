# =============================================================================
# AZURE SQL DATABASE MODULE
# =============================================================================

locals {
  naming_prefix = "${var.customer_id}-${var.spoke_name}-${var.region_code}"
  sql_server_name = coalesce(var.sql_server_name, "sql-${local.naming_prefix}")
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "SQL-Database"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# SQL SERVER
# -----------------------------------------------------------------------------

resource "random_string" "sql_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_mssql_server" "main" {
  name                         = "${local.sql_server_name}-${random_string.sql_suffix.result}"
  resource_group_name          = var.resource_group_name
  location                     = var.region
  version                      = var.sql_version
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_password
  
  minimum_tls_version          = "1.2"
  public_network_access_enabled = var.public_network_access_enabled
  
  dynamic "azuread_administrator" {
    for_each = var.enable_azure_ad_authentication && var.azuread_administrator != null ? [1] : []
    content {
      login_username = var.azuread_administrator.login_username
      object_id      = var.azuread_administrator.object_id
    }
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SQL DATABASE
# -----------------------------------------------------------------------------

resource "azurerm_mssql_database" "main" {
  name      = var.database_name
  server_id = azurerm_mssql_server.main.id
  
  sku_name    = var.sku_name
  max_size_gb = var.max_size_gb
  
  # Serverless configuration (cost optimization)
  min_capacity                = var.min_capacity
  auto_pause_delay_in_minutes = var.auto_pause_delay_in_minutes
  
  zone_redundant              = var.zone_redundant
  read_replica_count          = var.read_replica_count
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# BACKUP CONFIGURATION
# -----------------------------------------------------------------------------

resource "azurerm_mssql_database_extended_auditing_policy" "main" {
  database_id                             = azurerm_mssql_database.main.id
  log_monitoring_enabled                  = true
  retention_in_days                       = var.backup_retention_days
}

# Long-term retention
resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  server_id                   = azurerm_mssql_server.main.id
  log_monitoring_enabled      = true
  retention_in_days           = var.backup_retention_days
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-${local.sql_server_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.sql_server_name}"
    private_connection_resource_id = azurerm_mssql_server.main.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
  
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SECURITY - THREAT DETECTION
# -----------------------------------------------------------------------------

resource "azurerm_mssql_server_security_alert_policy" "main" {
  count = var.enable_threat_detection ? 1 : 0
  
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mssql_server.main.name
  state               = "Enabled"
  
  retention_days = 30
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "sql_server" {
  name                       = "diag-${local.sql_server_name}"
  target_resource_id         = azurerm_mssql_server.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "SQLSecurityAuditEvents"
  }
  
  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "sql_database" {
  name                       = "diag-${var.database_name}"
  target_resource_id         = azurerm_mssql_database.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "SQLInsights"
  }
  
  enabled_log {
    category = "AutomaticTuning"
  }
  
  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }
  
  enabled_log {
    category = "QueryStoreWaitStatistics"
  }
  
  enabled_log {
    category = "Errors"
  }
  
  enabled_log {
    category = "DatabaseWaitStatistics"
  }
  
  enabled_log {
    category = "Timeouts"
  }
  
  enabled_log {
    category = "Blocks"
  }
  
  enabled_log {
    category = "Deadlocks"
  }
  
  metric {
    category = "AllMetrics"
  }
}