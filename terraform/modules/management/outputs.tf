# =============================================================================
# MANAGEMENT MODULE OUTPUTS
# =============================================================================
# Purpose: Export Management resources for use by Hub and Spoke modules
# Usage: Other modules reference these outputs for monitoring and compliance
# Best Practice: Comprehensive outputs for full integration capability
# =============================================================================

# -----------------------------------------------------------------------------
# RESOURCE GROUP OUTPUTS
# -----------------------------------------------------------------------------

output "resource_group_id" {
  description = "Management Resource Group ID"
  value       = azurerm_resource_group.management.id
}

output "resource_group_name" {
  description = "Management Resource Group name"
  value       = azurerm_resource_group.management.name
}

output "resource_group_location" {
  description = "Management Resource Group location"
  value       = azurerm_resource_group.management.location
}

# =============================================================================
# LOG ANALYTICS WORKSPACE OUTPUTS (CRITICAL - Required by all modules)
# =============================================================================

# -----------------------------------------------------------------------------
# CENTRAL LAW (Primary - Used by Hub and Spoke modules)
# -----------------------------------------------------------------------------

output "central_workspace_id" {
  description = "Central Log Analytics Workspace ID (CRITICAL: Used by all diagnostic settings)"
  value       = var.enable_central_law ? azurerm_log_analytics_workspace.central[0].id : null
}

output "central_workspace_name" {
  description = "Central Log Analytics Workspace name"
  value       = var.enable_central_law ? azurerm_log_analytics_workspace.central[0].name : null
}

output "central_workspace_key" {
  description = "Central LAW primary shared key (sensitive - for agent configuration)"
  value       = var.enable_central_law ? azurerm_log_analytics_workspace.central[0].primary_shared_key : null
  sensitive   = true
}

output "central_workspace_resource_id" {
  description = "Central LAW Azure Resource ID"
  value       = var.enable_central_law ? azurerm_log_analytics_workspace.central[0].id : null
}

output "central_workspace_customer_id" {
  description = "Central LAW Customer ID (for agent configuration)"
  value       = var.enable_central_law ? azurerm_log_analytics_workspace.central[0].workspace_id : null
}

# -----------------------------------------------------------------------------
# TEAM-SPECIFIC WORKSPACES (Per your diagram)
# -----------------------------------------------------------------------------

output "team_workspaces" {
  description = "Map of team workspace names to their IDs and details"
  value = var.enable_team_workspaces ? {
    for name, workspace in azurerm_log_analytics_workspace.team : name => {
      id             = workspace.id
      name           = workspace.name
      workspace_id   = workspace.workspace_id
      retention_days = workspace.retention_in_days
      daily_quota_gb = workspace.daily_quota_gb
      primary_key    = workspace.primary_shared_key
      purpose        = var.team_workspaces[name].purpose
    }
  } : {}
  sensitive = true
}

output "team_workspace_ids" {
  description = "Map of team names to their workspace IDs"
  value = var.enable_team_workspaces ? {
    for name, workspace in azurerm_log_analytics_workspace.team : name => workspace.id
  } : {}
}
# -----------------------------------------------------------------------------
# OUTPUTS - Only NEW outputs (avoid duplicates with outputs.tf)
# -----------------------------------------------------------------------------

output "spoke_workspace_ids" {
  description = "Map of spoke workspace IDs (spoke_name → workspace_id)"
  value       = { for k, v in azurerm_log_analytics_workspace.spoke : k => v.id }
  sensitive   = true
}

output "spoke_workspace_names" {
  description = "Map of spoke workspace names"
  value       = { for k, v in azurerm_log_analytics_workspace.spoke : k => v.name }
}

output "spoke_workspace_details" {
  description = "Detailed information about spoke workspaces"
  value = {
    for k, v in azurerm_log_analytics_workspace.spoke : k => {
      id             = v.id
      name           = v.name
      workspace_id   = v.workspace_id
      retention_days = v.retention_in_days
      daily_quota_gb = v.daily_quota_gb
    }
  }
  sensitive = true
}

output "audit_workspace_name" {
  description = "Audit workspace name (7-year retention)"
  value       = var.enable_audit_workspace ? azurerm_log_analytics_workspace.audit[0].name : null
}

output "log_forwarding_enabled" {
  description = "Whether log forwarding from spoke to central is enabled"
  value       = var.enable_log_forwarding
}
# =============================================================================
# AZURE MONITOR OUTPUTS (Alerting & Monitoring)
# =============================================================================

output "action_group_id" {
  description = "Action Group ID for alert notifications"
  value       = var.enable_action_groups ? azurerm_monitor_action_group.alerts[0].id : null
}

output "action_group_name" {
  description = "Action Group name"
  value       = var.enable_action_groups ? azurerm_monitor_action_group.alerts[0].name : null
}

output "alert_rules" {
  description = "Map of deployed KQL alert rules"
  value = var.enable_central_law && var.enable_kql_alert_rules ? {
    for name, rule in azurerm_monitor_scheduled_query_rules_alert_v2.kql_alerts : name => {
      id       = rule.id
      name     = rule.name
      severity = rule.severity
      enabled  = rule.enabled
    }
  } : {}
}

output "alert_email_receivers" {
  description = "List of email addresses receiving alerts"
  value       = var.alert_email_receivers
}

# =============================================================================
# EVENT HUB OUTPUTS (SIEM Integration)
# =============================================================================

output "event_hub_namespace_id" {
  description = "Event Hub Namespace ID for SIEM integration"
  value       = var.enable_event_hub_export ? azurerm_eventhub_namespace.logs[0].id : null
}

output "event_hub_name" {
  description = "Event Hub name for log streaming"
  value       = var.enable_event_hub_export ? azurerm_eventhub.logs[0].name : null
}

output "event_hub_connection_string" {
  description = "Event Hub connection string (sensitive)"
  value       = var.enable_event_hub_export ? azurerm_eventhub_namespace.logs[0].default_primary_connection_string : null
  sensitive   = true
}

# =============================================================================
# AZURE POLICY OUTPUTS (Governance)
# =============================================================================

output "management_group_id" {
  description = "Management Group ID for policy scope"
  value       = var.enable_azure_policy ? azurerm_management_group.customer[0].id : null
}

output "management_group_name" {
  description = "Management Group name"
  value       = var.enable_azure_policy ? azurerm_management_group.customer[0].display_name : null
}

output "policy_assignments" {
  description = "Map of deployed policy assignments"
  value = var.enable_azure_policy && var.enable_builtin_policies ? {
    for name, assignment in azurerm_management_group_policy_assignment.caf_policies : name => {
      id   = assignment.id
      name = assignment.name
    }
  } : {}
}

output "custom_policies" {
  description = "Map of custom policy definitions"
  value = var.enable_azure_policy ? {
    for name, policy in azurerm_policy_definition.custom : name => {
      id           = policy.id
      name         = policy.name
      display_name = policy.display_name
    }
  } : {}
}

# =============================================================================
# MICROSOFT DEFENDER OUTPUTS (Security Posture)
# =============================================================================

output "defender_enabled_plans" {
  description = "Map of enabled Defender plans and their tiers"
  value = var.enable_defender ? {
    for type, config in var.defender_plans : type => {
      tier    = config.tier
      enabled = config.enabled
    } if config.enabled
  } : {}
}

output "defender_workspace_id" {
  description = "Defender connected workspace ID"
  value       = var.enable_defender && var.enable_central_law ? azurerm_security_center_workspace.main[0].workspace_id : null
}

# =============================================================================
# BACKUP OUTPUTS (Disaster Recovery)
# =============================================================================

output "backup_vault_id" {
  description = "Recovery Services Vault ID"
  value       = var.enable_backup_vault ? azurerm_recovery_services_vault.backup[0].id : null
}

output "backup_vault_name" {
  description = "Recovery Services Vault name"
  value       = var.enable_backup_vault ? azurerm_recovery_services_vault.backup[0].name : null
}

output "backup_policy_vm_id" {
  description = "VM Backup Policy ID"
  value       = var.enable_backup_vault ? azurerm_backup_policy_vm.daily[0].id : null
}

output "backup_policy_vm_name" {
  description = "VM Backup Policy name"
  value       = var.enable_backup_vault ? azurerm_backup_policy_vm.daily[0].name : null
}

# =============================================================================
# COST MANAGEMENT OUTPUTS (Financial Tracking)
# =============================================================================

output "budget_id" {
  description = "Consumption Budget ID"
  value       = var.enable_budgets && var.monthly_budget_limit > 0 ? azurerm_consumption_budget_subscription.monthly[0].id : null
}

output "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  value       = var.monthly_budget_limit
}

output "budget_alert_thresholds" {
  description = "Budget alert thresholds (percentages)"
  value       = var.budget_alert_thresholds
}

# =============================================================================
# AUTOMATION ACCOUNT OUTPUTS (Runbooks & Automation)
# =============================================================================

output "automation_account_id" {
  description = "Automation Account ID"
  value       = azurerm_automation_account.management.id
}

output "automation_account_name" {
  description = "Automation Account name"
  value       = azurerm_automation_account.management.name
}

output "automation_account_endpoint" {
  description = "Automation Account endpoint URL"
  value       = azurerm_automation_account.management.dsc_server_endpoint
}

# =============================================================================
# COST TRACKING OUTPUTS (For Cost Intelligence Engine)
# =============================================================================

output "cost_tracking" {
  description = "Cost tracking configuration for cost intelligence engine"
  value = {
    # Customer identification
    customer_id = var.customer_id
    environment = var.environment
    component   = "Management"
    region      = var.region

    # Cost allocation tags
    cost_allocation_tags   = var.cost_allocation_tags
    cost_splitting_enabled = var.enable_cost_splitting

    # LAW costs
    central_law_sku            = var.central_law_sku
    central_law_retention_days = var.central_law_retention_days
    central_law_daily_quota_gb = var.central_law_daily_quota_gb
    commitment_tier_enabled    = var.enable_commitment_tiers
    commitment_tier_gb         = var.commitment_tier_gb

    # Team workspace costs
    team_workspaces = var.enable_team_workspaces ? {
      for name, config in var.team_workspaces : name => {
        retention_days = config.retention_days
        daily_quota_gb = config.daily_quota_gb
        estimated_cost = config.daily_quota_gb * 2.30 * 30 # $2.30/GB estimate
      }
    } : {}

    # Storage costs
    log_export_enabled        = var.enable_log_export
    log_export_retention_days = var.log_export_retention_days

    # Defender costs
    defender_enabled = var.enable_defender
    defender_plans = var.enable_defender ? [
      for type, config in var.defender_plans : type if config.enabled && config.tier == "Standard"
    ] : []

    # Resource IDs for cost queries
    resource_group_id     = azurerm_resource_group.management.id
    central_workspace_id  = var.enable_central_law ? azurerm_log_analytics_workspace.central[0].id : null
    storage_account_id    = var.enable_log_export ? azurerm_storage_account.log_export[0].id : null
    backup_vault_id       = var.enable_backup_vault ? azurerm_recovery_services_vault.backup[0].id : null
    automation_account_id = azurerm_automation_account.management.id
  }
}

# =============================================================================
# SECURITY & COMPLIANCE OUTPUTS (Audit & Reporting)
# =============================================================================

output "security_config" {
  description = "Security configuration summary for compliance reporting"
  value = {
    # Monitoring
    central_law_enabled   = var.enable_central_law
    team_workspaces_count = var.enable_team_workspaces ? length(var.team_workspaces) : 0
    log_export_enabled    = var.enable_log_export

    # Alerting
    action_groups_enabled = var.enable_action_groups
    kql_alert_rules_count = var.enable_kql_alert_rules ? length(var.alert_rules) : 0

    # Governance
    azure_policy_enabled = var.enable_azure_policy
    policy_mode          = var.policy_assignment_mode

    # Security
    defender_enabled = var.enable_defender
    defender_plans_active = var.enable_defender ? length([
      for type, config in var.defender_plans : type if config.enabled
    ]) : 0

    # Backup
    backup_enabled = var.enable_backup_vault

    # RBAC
    rbac_assignments_enabled = var.enable_rbac_assignments

    # Retention
    max_retention_days = max(
      var.central_law_retention_days,
      var.enable_team_workspaces ? max([for w in var.team_workspaces : w.retention_days]...) : 0,
      var.log_export_retention_days
    )
  }
}

# =============================================================================
# OPERATIONAL OUTPUTS (For Runbooks & Automation)
# =============================================================================

output "operational_info" {
  description = "Operational information for runbooks and automation"
  value = {
    # Naming convention
    naming_prefix = local.naming_prefix
    customer_id   = var.customer_id
    environment   = var.environment
    region_code   = var.region_code

    # Resource names (for scripts)
    resource_group_name     = azurerm_resource_group.management.name
    central_workspace_name  = var.enable_central_law ? azurerm_log_analytics_workspace.central[0].name : null
    storage_account_name    = var.enable_log_export ? azurerm_storage_account.log_export[0].name : null
    backup_vault_name       = var.enable_backup_vault ? azurerm_recovery_services_vault.backup[0].name : null
    automation_account_name = azurerm_automation_account.management.name

    # Deployment metadata
    deployment_date   = formatdate("YYYY-MM-DD", timestamp())
    terraform_managed = true
  }

}

# =============================================================================
# INTEGRATION OUTPUTS (For Hub and Spoke Modules)
# =============================================================================

output "monitoring_config" {
  description = "Complete monitoring configuration for Hub and Spoke consumption"
  value = {
    # Primary workspace (required by all modules)
    workspace_id   = var.enable_central_law ? azurerm_log_analytics_workspace.central[0].id : null
    workspace_name = var.enable_central_law ? azurerm_log_analytics_workspace.central[0].name : null

    # Action group for alerts
    action_group_id = var.enable_action_groups ? azurerm_monitor_action_group.alerts[0].id : null

    # Backup vault for VM protection
    backup_vault_id  = var.enable_backup_vault ? azurerm_recovery_services_vault.backup[0].id : null
    backup_policy_id = var.enable_backup_vault ? azurerm_backup_policy_vm.daily[0].id : null

    # Storage for log export
    log_storage_id = var.enable_log_export ? azurerm_storage_account.log_export[0].id : null

    # Defender settings
    defender_enabled = var.enable_defender

    # Policy settings
    policy_enabled      = var.enable_azure_policy
    management_group_id = var.enable_azure_policy ? azurerm_management_group.customer[0].id : null
  }
}

# =============================================================================
# WORKSPACE ENDPOINTS (For Direct API Access)
# =============================================================================

output "workspace_endpoints" {
  description = "API endpoints for Log Analytics workspaces"
  value = {
    central = var.enable_central_law ? {
      portal_url = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_log_analytics_workspace.central[0].id}"
      api_url    = "https://api.loganalytics.io/v1/workspaces/${azurerm_log_analytics_workspace.central[0].workspace_id}"
    } : null

    teams = var.enable_team_workspaces ? {
      for name, workspace in azurerm_log_analytics_workspace.team : name => {
        portal_url = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${workspace.id}"
        api_url    = "https://api.loganalytics.io/v1/workspaces/${workspace.workspace_id}"
      }
    } : {}
  }
}

# =============================================================================
# TABLE RETENTION CONFIGURATION (For Cost Intelligence)
# =============================================================================

output "table_retention_config" {
  description = "Table-level retention configuration for cost optimization tracking"
  value = var.enable_table_retention ? {
    overrides  = var.table_retention_overrides
    basic_logs = var.basic_log_tables

    # Cost estimates per table type
    estimated_costs = {
      for table, config in var.table_retention_overrides : table => {
        retention_days = config.retention_days
        archive_days   = config.archive_days
        active_cost    = "${config.retention_days * 0.10} USD/GB" # Active: $0.10/GB/day
        archive_cost   = "${config.archive_days * 0.02} USD/GB"   # Archive: $0.02/GB/day
      }
    }
  } : null
}

# =============================================================================
# SUMMARY OUTPUT (Human-Readable)
# =============================================================================
output "deployment_summary" {
  description = "Human-readable deployment summary"
  value       = <<-EOT
    ============================================================
    Azure CAF-LZ Management Subscription Deployment Summary
    ============================================================
    Customer ID:          ${var.customer_id}
    Environment:          ${var.environment}
    Region:               ${var.region} (${var.region_code})
    
    LOG ANALYTICS:
    Central Workspace:    ${var.enable_central_law ? azurerm_log_analytics_workspace.central[0].name : "Disabled"}
    Retention (Central):  ${var.central_law_retention_days} days
    Team Workspaces:      ${var.enable_team_workspaces ? length(var.team_workspaces) : 0}
      - Operations:       ${var.enable_team_workspaces && contains(keys(var.team_workspaces), "operations") ? "${var.team_workspaces["operations"].retention_days} days" : "N/A"}
      - Security:         ${var.enable_team_workspaces && contains(keys(var.team_workspaces), "security") ? "${var.team_workspaces["security"].retention_days} days" : "N/A"}
    
    MONITORING:
    Action Groups:        ${var.enable_action_groups ? "Enabled" : "Disabled"}
    Alert Rules:          ${var.enable_kql_alert_rules ? length(var.alert_rules) : 0}
    Event Hub (SIEM):     ${var.enable_event_hub_export ? "Enabled" : "Disabled"}
    
    SECURITY:
    Azure Policy:         ${var.enable_azure_policy ? "Enabled" : "Disabled"}
    Defender for Cloud:   ${var.enable_defender ? "Enabled" : "Disabled"}
    Defender Plans:       ${var.enable_defender ? length([for k, v in var.defender_plans : k if v.enabled]) : 0}
    
    BACKUP:
    Recovery Vault:       ${var.enable_backup_vault ? azurerm_recovery_services_vault.backup[0].name : "Disabled"}
    
    COST MANAGEMENT:
    Monthly Budget:       ${var.monthly_budget_limit > 0 ? "$${var.monthly_budget_limit}" : "No limit"}
    Cost Splitting:       ${var.enable_cost_splitting ? "Enabled" : "Disabled"}
    
    STORAGE:
    Log Export:           ${var.enable_log_export ? "Enabled (${var.log_export_retention_days} days)" : "Disabled"}
    
    Cost Center:          Platform-Management-${var.customer_id}
    ============================================================
  EOT
}