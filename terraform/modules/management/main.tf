# =============================================================================
# AZURE CAF-LZ MANAGEMENT MODULE
# =============================================================================
# Purpose: Centralized monitoring, logging, policy, security, and cost management
# Components: Log Analytics (multi-workspace), Azure Monitor, Policy, Defender, Backup
# Best Practices: Tag-based cost allocation, table-level retention, read-only access
# =============================================================================

# -----------------------------------------------------------------------------
# LOCAL VARIABLES - Naming Convention & Calculated Values
# -----------------------------------------------------------------------------

locals {
  # Naming convention: <resource-type>-<customer-id>-mgmt-<region-code>
  naming_prefix = "${var.customer_id}-mgmt-${var.region_code}"

  # Resource names following Azure naming best practices
  resource_group_name      = "rg-${local.naming_prefix}"
  central_law_name         = "law-${local.naming_prefix}-central"
  automation_account_name  = "aa-${local.naming_prefix}"
  backup_vault_name        = "rsv-${local.naming_prefix}"
  storage_account_name     = "st${var.customer_id}mgmt${var.region_code}" # No dashes for storage
  action_group_name        = "ag-${local.naming_prefix}"
  event_hub_namespace_name = "evhns-${local.naming_prefix}"

  # Comprehensive tagging strategy for cost tracking and governance
  common_tags = merge(
    {
      # Mandatory tags for cost allocation
      Customer    = var.customer_id
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "Management"
      CostCenter  = "Platform-Management-${var.customer_id}"

      # Operational tags
      DeploymentDate = formatdate("YYYY-MM-DD", timestamp())
      Region         = var.region

      # Cost optimization tags
      Purpose          = "Centralized-Monitoring"
      CriticalityLevel = "Critical"

      # Compliance tags
      DataClassification = "Internal"
      Compliance         = "CAF-LZ"
      BackupEnabled      = "true"
    },
    var.tags,
    var.mandatory_tags
  )
}

# -----------------------------------------------------------------------------
# RESOURCE GROUP
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "management" {
  name     = local.resource_group_name
  location = var.region
  tags     = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["DeploymentDate"]
    ]
  }
}

# =============================================================================
# LOG ANALYTICS WORKSPACES (MULTI-WORKSPACE ARCHITECTURE)
# =============================================================================

# -----------------------------------------------------------------------------
# CENTRAL LOG ANALYTICS WORKSPACE (Primary)
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "central" {
  count = var.enable_central_law ? 1 : 0

  name                = local.central_law_name
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = var.central_law_sku
  retention_in_days   = var.central_law_retention_days
  daily_quota_gb      = var.central_law_daily_quota_gb

  # Cost optimization: Commitment tier (15-30% savings for predictable usage)
  reservation_capacity_in_gb_per_day = var.enable_commitment_tiers ? var.commitment_tier_gb : null

  # Enable internet ingestion and query (required for cross-subscription)
  internet_ingestion_enabled = true
  internet_query_enabled     = true

  tags = merge(
    local.common_tags,
    {
      Name      = local.central_law_name
      Purpose   = "Central log aggregation for all subscriptions"
      Workspace = "Central"
    }
  )
}

# Diagnostic Settings for Central LAW (monitor the monitor!)
resource "azurerm_monitor_diagnostic_setting" "central_law" {
  count = var.enable_central_law ? 1 : 0

  name                       = "diag-${local.central_law_name}"
  target_resource_id         = azurerm_log_analytics_workspace.central[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.central[0].id

  enabled_log {
    category = "Audit"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# -----------------------------------------------------------------------------
# TEAM-SPECIFIC LOG ANALYTICS WORKSPACES (Per your diagram)
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "team" {
  for_each = var.enable_team_workspaces ? var.team_workspaces : {}

  name                = "law-${var.customer_id}-${each.key}-${var.region_code}"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "PerGB2018"
  retention_in_days   = each.value.retention_days
  daily_quota_gb      = each.value.daily_quota_gb

  internet_ingestion_enabled = true
  internet_query_enabled     = true

  tags = merge(
    local.common_tags,
    {
      Name           = "law-${var.customer_id}-${each.key}-${var.region_code}"
      Purpose        = each.value.purpose
      Workspace      = title(each.key)
      Team           = "Team-${title(each.key)}"
      RetentionDays  = tostring(each.value.retention_days)
      CostAllocation = each.key
    }
  )
}

# -----------------------------------------------------------------------------
# TABLE-LEVEL RETENTION CONFIGURATION (Granular cost control)
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_storage_insights" "table_retention" {
  for_each = var.enable_central_law && var.enable_table_retention ? var.table_retention_overrides : {}

  name                = "retention-${each.key}"
  resource_group_name = azurerm_resource_group.management.name
  workspace_id        = azurerm_log_analytics_workspace.central[0].id
  storage_account_id  = azurerm_storage_account.log_export[0].id
  storage_account_key = azurerm_storage_account.log_export[0].primary_access_key

  # Note: Table-level retention requires Azure CLI or REST API for full implementation
  # This resource configures storage insights for archival


}

# -----------------------------------------------------------------------------
# BASIC LOGS CONFIGURATION (80% cost savings for high-volume logs)
# -----------------------------------------------------------------------------

# Note: Basic logs tier is configured via Azure CLI or REST API post-deployment
# Tables in var.basic_log_tables will be set to Basic tier (8-day retention, limited queries)

# =============================================================================
# STORAGE ACCOUNT FOR LOG EXPORT (Long-term retention)
# =============================================================================

resource "azurerm_storage_account" "log_export" {
  count = var.enable_log_export ? 1 : 0

  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.management.name
  location                 = azurerm_resource_group.management.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Geo-redundant for compliance
  account_kind             = "StorageV2"

  # Security
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  # Cost optimization: Cool tier for archived logs
  access_tier = "Cool"

  # Lifecycle management for cost optimization
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = var.log_export_retention_days
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name    = local.storage_account_name
      Purpose = "Long-term log archival (cheaper than LAW)"
    }
  )
}

# Container for exported logs
resource "azurerm_storage_container" "logs" {
  count = var.enable_log_export ? 1 : 0

  name                  = "logs"
  storage_account_name  = azurerm_storage_account.log_export[0].name
  container_access_type = "private"
}

# Lifecycle policy for automatic archival
resource "azurerm_storage_management_policy" "log_archival" {
  count = var.enable_log_export ? 1 : 0

  storage_account_id = azurerm_storage_account.log_export[0].id

  rule {
    name    = "archive-old-logs"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        # Move to Cool tier after 30 days
        tier_to_cool_after_days_since_modification_greater_than = 30

        # Move to Archive tier after 90 days (cheapest storage)
        tier_to_archive_after_days_since_modification_greater_than = 90

        # Delete after retention period
        delete_after_days_since_modification_greater_than = var.log_export_retention_days
      }
    }
  }
}

# =============================================================================
# DATA EXPORT RULES (LAW to Storage)
# =============================================================================

resource "azurerm_log_analytics_data_export_rule" "to_storage" {
  for_each = var.enable_central_law && var.enable_log_export ? toset(["SecurityEvent", "AuditLogs", "AzureActivity"]) : []

  name                    = "export-${each.key}"
  resource_group_name     = azurerm_resource_group.management.name
  workspace_resource_id   = azurerm_log_analytics_workspace.central[0].id
  destination_resource_id = azurerm_storage_account.log_export[0].id
  table_names             = [each.key]
  enabled                 = true
}

# =============================================================================
# EVENT HUB (Optional - for SIEM integration)
# =============================================================================

resource "azurerm_eventhub_namespace" "logs" {
  count = var.enable_event_hub_export ? 1 : 0

  name                = local.event_hub_namespace_name
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "Standard"
  capacity            = 1

  tags = merge(
    local.common_tags,
    {
      Name    = local.event_hub_namespace_name
      Purpose = "Log streaming to SIEM"
    }
  )
}

resource "azurerm_eventhub" "logs" {
  count = var.enable_event_hub_export ? 1 : 0

  name                = "logs"
  namespace_name      = azurerm_eventhub_namespace.logs[0].name
  resource_group_name = azurerm_resource_group.management.name
  partition_count     = 4
  message_retention   = 7
}

# =============================================================================
# AZURE MONITOR - ACTION GROUPS (Email Notifications)
# =============================================================================

resource "azurerm_monitor_action_group" "alerts" {
  count = var.enable_action_groups ? 1 : 0

  name                = local.action_group_name
  resource_group_name = azurerm_resource_group.management.name
  short_name          = substr(var.customer_id, 0, 12)

  # Email receivers
  dynamic "email_receiver" {
    for_each = var.alert_email_receivers
    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name    = local.action_group_name
      Purpose = "Alert notifications"
    }
  )
}

# =============================================================================
# KQL ALERT RULES (Proactive Monitoring)
# =============================================================================

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "kql_alerts" {
  for_each = var.enable_central_law && var.enable_kql_alert_rules ? var.alert_rules : {}

  name                = "alert-${each.key}"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

  evaluation_frequency = "PT${each.value.frequency}M"
  window_duration      = "PT${each.value.time_window}M"
  scopes               = [azurerm_log_analytics_workspace.central[0].id]
  severity             = each.value.severity

  criteria {
    query                   = each.value.query
    time_aggregation_method = "Count"
    threshold               = each.value.threshold
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = var.enable_action_groups ? [azurerm_monitor_action_group.alerts[0].id] : []
  }

  description = "KQL-based alert for ${each.key}"
  enabled     = true

  tags = merge(
    local.common_tags,
    {
      Name     = "alert-${each.key}"
      Severity = tostring(each.value.severity)
    }
  )
}

# =============================================================================
# AZURE POLICY (Governance & Compliance)
# =============================================================================

# Management Group (for policy scope)
resource "azurerm_management_group" "customer" {
  count = var.enable_azure_policy ? 1 : 0

  display_name = "${var.customer_id}-management-group"
  name         = "${var.customer_id}-mg"
}

# Built-in Policy Assignments (CAF recommendations)
resource "azurerm_management_group_policy_assignment" "caf_policies" {
  for_each = var.enable_azure_policy && var.enable_builtin_policies ? toset([
    "Require-Tags-On-Resources",
    "Audit-VM-Managed-Disks",
    "Enforce-TLS-1.2"
  ]) : []

  name                 = "policy-${each.key}"
  management_group_id  = azurerm_management_group.customer[0].id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/${each.key}"
  location             = var.region
  parameters = jsonencode({
    effect = {
      value = var.policy_assignment_mode
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

# Custom Policy Definitions
resource "azurerm_policy_definition" "custom" {
  for_each = var.enable_azure_policy ? var.custom_policies : {}

  name         = each.key
  policy_type  = "Custom"
  mode         = each.value.mode
  display_name = each.value.display_name
  description  = each.value.description

  management_group_id = azurerm_management_group.customer[0].id

  policy_rule = each.value.policy_rule
  parameters  = each.value.parameters
}

# =============================================================================
# MICROSOFT DEFENDER FOR CLOUD
# =============================================================================

resource "azurerm_security_center_subscription_pricing" "defender" {
  for_each = var.enable_defender ? var.defender_plans : {}

  tier          = each.value.tier
  resource_type = each.key
}



# Defender Workspace Connection
resource "azurerm_security_center_workspace" "main" {
  count = var.enable_defender && var.enable_central_law ? 1 : 0

  scope        = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  workspace_id = azurerm_log_analytics_workspace.central[0].id
}

# =============================================================================
# AZURE BACKUP (Recovery Services Vault)
# =============================================================================

resource "azurerm_recovery_services_vault" "backup" {
  count = var.enable_backup_vault ? 1 : 0

  name                = local.backup_vault_name
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "Standard"

  soft_delete_enabled = true

  tags = merge(
    local.common_tags,
    {
      Name    = local.backup_vault_name
      Purpose = "Centralized backup for VMs and databases"
    }
  )
}

# VM Backup Policy
resource "azurerm_backup_policy_vm" "daily" {
  count = var.enable_backup_vault ? 1 : 0

  name                = "policy-vm-daily"
  resource_group_name = azurerm_resource_group.management.name
  recovery_vault_name = azurerm_recovery_services_vault.backup[0].name

  backup {
    frequency = var.backup_policy_vm.frequency
    time      = var.backup_policy_vm.time
  }

  retention_daily {
    count = var.backup_policy_vm.retention_daily
  }

  retention_weekly {
    count    = var.backup_policy_vm.retention_weekly
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = var.backup_policy_vm.retention_monthly
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }

  retention_yearly {
    count    = var.backup_policy_vm.retention_yearly
    weekdays = ["Sunday"]
    weeks    = ["First"]
    months   = ["January"]
  }
}

# =============================================================================
# COST MANAGEMENT & BUDGETS
# =============================================================================

# Budget for entire customer deployment
resource "azurerm_consumption_budget_subscription" "monthly" {
  count = var.enable_budgets && var.monthly_budget_limit > 0 ? 1 : 0

  name            = "budget-${var.customer_id}-monthly"
  subscription_id = data.azurerm_client_config.current.subscription_id

  amount     = var.monthly_budget_limit
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  # Alert thresholds
  dynamic "notification" {
    for_each = var.budget_alert_thresholds
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Actual"

      contact_emails = var.alert_email_receivers
    }
  }
}

# =============================================================================
# AUTOMATION ACCOUNT (For runbooks and automation)
# =============================================================================

resource "azurerm_automation_account" "management" {
  name                = local.automation_account_name
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku_name            = "Basic"

  tags = merge(
    local.common_tags,
    {
      Name    = local.automation_account_name
      Purpose = "Cost optimization and automation runbooks"
    }
  )
}

# Link Automation Account to LAW
resource "azurerm_log_analytics_linked_service" "automation" {
  count = var.enable_central_law ? 1 : 0

  resource_group_name = azurerm_resource_group.management.name
  workspace_id        = azurerm_log_analytics_workspace.central[0].id
  read_access_id      = azurerm_automation_account.management.id
}

# =============================================================================
# RBAC ASSIGNMENTS (Read-Only Access from your diagram)
# =============================================================================

# Read-only access to Central LAW for all teams
resource "azurerm_role_assignment" "law_readers_central" {
  for_each = var.enable_rbac_assignments ? toset(flatten([
    for team, users in var.log_analytics_readers : users
  ])) : []

  scope                = azurerm_log_analytics_workspace.central[0].id
  role_definition_name = "Log Analytics Reader"
  principal_id         = each.value
}

# Team-specific LAW access
resource "azurerm_role_assignment" "law_readers_team" {
  for_each = var.enable_rbac_assignments && var.enable_team_workspaces ? {
    for combo in flatten([
      for team, users in var.log_analytics_readers : [
        for user in users : {
          team = team
          user = user
        }
      ]
    ]) : "${combo.team}-${combo.user}" => combo
  } : {}

  scope                = azurerm_log_analytics_workspace.team[each.value.team].id
  role_definition_name = "Log Analytics Reader"
  principal_id         = each.value.user
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}