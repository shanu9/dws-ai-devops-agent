# =============================================================================
# ENHANCED LOGGING ARCHITECTURE - Multi-Workspace Setup
# =============================================================================
# Per your architecture diagram:
# 1. Central LAW - aggregates logs from all spokes
# 2. Per-Spoke LAWs - each spoke has dedicated workspace
# 3. Audit LAW - 7-year retention for compliance
# 4. Log forwarding from spoke LAWs → Central LAW
# 5. Long-term archival to Storage Account

# -----------------------------------------------------------------------------
# PER-SPOKE LOG ANALYTICS WORKSPACES
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "spoke" {
  for_each = var.spoke_workspaces

  name                = "law-${var.customer_id}-${each.key}-${var.region_code}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name

  sku               = "PerGB2018"
  retention_in_days = each.value.retention_days
  daily_quota_gb    = each.value.daily_quota_gb

  # Enable cross-subscription access
  internet_ingestion_enabled = true
  internet_query_enabled     = true

  tags = merge(
    local.common_tags,
    {
      Name          = "law-${var.customer_id}-${each.key}-${var.region_code}"
      Purpose       = "Dedicated workspace for ${each.key} spoke"
      Spoke         = each.key
      CostCenter    = each.value.cost_center
      RetentionDays = tostring(each.value.retention_days)
    }
  )
}

# -----------------------------------------------------------------------------
# AUDIT LOG ANALYTICS WORKSPACE (7-year retention for compliance)
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "audit" {
  count = var.enable_audit_workspace ? 1 : 0

  name                = "law-${var.customer_id}-audit-${var.region_code}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name

  sku               = "PerGB2018"
  retention_in_days = 730 # 7 years (maximum for compliance)
  daily_quota_gb    = var.audit_workspace_daily_quota_gb

  internet_ingestion_enabled = true
  internet_query_enabled     = true

  tags = merge(
    local.common_tags,
    {
      Name          = "law-${var.customer_id}-audit-${var.region_code}"
      Purpose       = "Audit logs with 7-year retention"
      Compliance    = "Required"
      RetentionDays = "730"
      CostImpact    = "High"
    }
  )
}

# -----------------------------------------------------------------------------
# DATA EXPORT RULES - Forward Spoke Logs to Central LAW
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_data_export_rule" "spoke_to_central" {
  for_each = var.enable_central_law && var.enable_log_forwarding ? var.spoke_workspaces : {}

  name                    = "export-${each.key}-to-central"
  resource_group_name     = azurerm_resource_group.management.name
  workspace_resource_id   = azurerm_log_analytics_workspace.spoke[each.key].id
  destination_resource_id = azurerm_log_analytics_workspace.central[0].id

  # Forward key tables to central workspace
  table_names = [
    "AzureActivity",
    "AzureDiagnostics",
    "AzureMetrics",
    "Heartbeat",
    "Perf",
    "Syslog",
    "SecurityEvent",
    "Event"
  ]

  enabled = true
}

# -----------------------------------------------------------------------------
# DATA EXPORT RULES - Forward Audit Logs to Audit Workspace
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_data_export_rule" "central_to_audit" {
  count = var.enable_central_law && var.enable_audit_workspace ? 1 : 0

  name                    = "export-central-to-audit"
  resource_group_name     = azurerm_resource_group.management.name
  workspace_resource_id   = azurerm_log_analytics_workspace.central[0].id
  destination_resource_id = azurerm_log_analytics_workspace.audit[0].id

  # Only audit-relevant tables (cost optimization)
  table_names = [
    "AuditLogs",
    "SignInLogs",
    "AzureActivity",
    "SecurityEvent",
    "IdentityInfo"
  ]

  enabled = true
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS - Spoke Workspaces
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "spoke_workspaces" {
  for_each = var.spoke_workspaces

  name                       = "diag-law-${each.key}"
  target_resource_id         = azurerm_log_analytics_workspace.spoke[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central[0].id

  enabled_log {
    category = "Audit"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
