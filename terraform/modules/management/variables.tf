# =============================================================================
# GLOBAL VARIABLES - Naming & Identification
# =============================================================================

variable "customer_id" {
  description = "Unique customer identifier (3-6 characters, lowercase alphanumeric)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,6}$", var.customer_id))
    error_message = "Customer ID must be 3-6 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment name (dev/stg/prd)"
  type        = string
  default     = "prd"
  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "Environment must be dev, stg, or prd."
  }
}

variable "region" {
  description = "Azure region for management resources"
  type        = string
}

variable "region_code" {
  description = "Short region code (e.g., eus, wus, jpe, jpw)"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2,4}$", var.region_code))
    error_message = "Region code must be 2-4 lowercase letters."
  }
}

# =============================================================================
# LOG ANALYTICS WORKSPACE CONFIGURATION (CRITICAL FOR COST OPTIMIZATION)
# =============================================================================

# Central LAW for all subscriptions
variable "enable_central_law" {
  description = "Deploy central Log Analytics Workspace for all logs"
  type        = bool
  default     = true
}

variable "central_law_sku" {
  description = "Central LAW SKU (PerGB2018 recommended, CapacityReservation for high volume)"
  type        = string
  default     = "PerGB2018"
  validation {
    condition     = contains(["Free", "PerNode", "PerGB2018", "Standalone", "CapacityReservation"], var.central_law_sku)
    error_message = "Valid SKUs: Free, PerNode, PerGB2018, Standalone, CapacityReservation."
  }
}

variable "central_law_retention_days" {
  description = "Default retention for central LAW (30-730 days, or 0 for unlimited)"
  type        = number
  default     = 90
  validation {
    condition     = (var.central_law_retention_days >= 30 && var.central_law_retention_days <= 730) || var.central_law_retention_days == 0
    error_message = "Retention must be 30-730 days, or 0 for unlimited."
  }
}

variable "central_law_daily_quota_gb" {
  description = "Daily ingestion quota in GB for central LAW (cost control). -1 = unlimited"
  type        = number
  default     = -1
}

# Per-Team Log Analytics Workspaces (From your diagram)
variable "enable_team_workspaces" {
  description = "Create separate LAW per team with different retention policies"
  type        = bool
  default     = true
}

variable "team_workspaces" {
  description = "Team-specific workspaces with custom retention (aligned to your diagram)"
  type = map(object({
    retention_days = number
    daily_quota_gb = number
    purpose        = string
  }))
  default = {
    "operations" = {
      retention_days = 90 # LAW-TeamA-Operations (90 days)
      daily_quota_gb = 50
      purpose        = "Operational logs and metrics"
    }
    "security" = {
      retention_days = 730 # LAW-TeamA-Security (2 years)
      daily_quota_gb = 100
      purpose        = "Security and compliance logs"
    }
    "audit" = {
      retention_days = 2555 # LAW-TeamB-Audit (7 years) - compliance requirement
      daily_quota_gb = 30
      purpose        = "Audit and regulatory logs"
    }
  }
}

# Table-level retention (granular control per log type)
variable "enable_table_retention" {
  description = "Enable different retention per table type (e.g., Security 2yr, Perf 30d)"
  type        = bool
  default     = true
}

variable "table_retention_overrides" {
  description = "Specific retention per table type for cost optimization"
  type = map(object({
    retention_days = number
    archive_days   = number # Archive to cheaper storage after N days
  }))
  default = {
    # Security tables - long retention
    "SecurityEvent" = {
      retention_days = 730 # 2 years active
      archive_days   = 365 # Archive after 1 year
    }
    "AuditLogs" = {
      retention_days = 2555 # 7 years (compliance)
      archive_days   = 730
    }

    # Operational tables - short retention
    "Perf" = {
      retention_days = 30
      archive_days   = 0
    }
    "Heartbeat" = {
      retention_days = 30
      archive_days   = 0
    }

    # Firewall logs - medium retention
    "AzureFirewallApplicationRule" = {
      retention_days = 90
      archive_days   = 60
    }
    "AzureFirewallNetworkRule" = {
      retention_days = 90
      archive_days   = 60
    }

    # Cost management - keep long for trend analysis
    "AzureCostManagement" = {
      retention_days = 365
      archive_days   = 180
    }
  }
}

# =============================================================================
# COST ALLOCATION & TAGGING STRATEGY
# =============================================================================

variable "cost_allocation_tags" {
  description = "Tags for cost allocation across spokes (from your diagram)"
  type = map(object({
    cost_center  = string
    team         = string
    chargeback   = bool
    budget_alert = number
  }))
  default = {
    "spoke-prod" = {
      cost_center  = "Production-Workloads"
      team         = "TeamA-Operations"
      chargeback   = true
      budget_alert = 50000 # Alert at $50K/month
    }
    "spoke-dev" = {
      cost_center  = "Development"
      team         = "TeamB-Operations"
      chargeback   = false
      budget_alert = 10000
    }
  }
}

variable "enable_cost_splitting" {
  description = "Enable cost split across all spokes using tags"
  type        = bool
  default     = true
}

# =============================================================================
# AZURE MONITOR & ALERTS
# =============================================================================

variable "enable_azure_monitor" {
  description = "Deploy Azure Monitor for centralized monitoring"
  type        = bool
  default     = true
}

variable "enable_action_groups" {
  description = "Create Action Groups for email notifications"
  type        = bool
  default     = true
}

variable "alert_email_receivers" {
  description = "Email addresses for alert notifications"
  type        = list(string)
  default     = []
}

variable "enable_kql_alert_rules" {
  description = "Deploy KQL-based alert rules (read-only queries from your diagram)"
  type        = bool
  default     = true
}

# Predefined alert rules (from your architecture)
variable "alert_rules" {
  description = "KQL alert queries for proactive monitoring"
  type = map(object({
    query       = string
    severity    = number
    frequency   = number
    time_window = number
    threshold   = number
  }))
  default = {
    "high-firewall-denies" = {
      query       = <<-QUERY
        AzureFirewallNetworkRule
        | where Action == "Deny"
        | summarize DenyCount = count() by bin(TimeGenerated, 5m)
        | where DenyCount > 100
      QUERY
      severity    = 2
      frequency   = 5
      time_window = 15
      threshold   = 100
    }

    "vm-high-cpu" = {
      query       = <<-QUERY
        Perf
        | where ObjectName == "Processor" and CounterName == "% Processor Time"
        | where CounterValue > 90
        | summarize AggregatedValue = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
      QUERY
      severity    = 3
      frequency   = 5
      time_window = 15
      threshold   = 90
    }

    "cost-spike-detected" = {
      query       = <<-QUERY
        AzureCostManagement
        | summarize TodayCost = sum(Cost) by bin(TimeGenerated, 1d)
        | extend AvgCost = avg(TodayCost)
        | where TodayCost > AvgCost * 1.5
      QUERY
      severity    = 2
      frequency   = 60
      time_window = 120
      threshold   = 1
    }
  }
}

# =============================================================================
# AZURE POLICY & GOVERNANCE
# =============================================================================

variable "enable_azure_policy" {
  description = "Deploy Azure Policy for governance and compliance"
  type        = bool
  default     = true
}

variable "policy_assignment_mode" {
  description = "Policy enforcement mode (DoNotEnforce/Default)"
  type        = string
  default     = "Default"
  validation {
    condition     = contains(["DoNotEnforce", "Default"], var.policy_assignment_mode)
    error_message = "Must be DoNotEnforce or Default."
  }
}

variable "enable_builtin_policies" {
  description = "Enable CAF-recommended built-in policies"
  type        = bool
  default     = true
}

variable "custom_policies" {
  description = "Custom policy definitions for specific requirements"
  type = map(object({
    display_name = string
    description  = string
    mode         = string
    policy_rule  = string
    parameters   = string
  }))
  default = {}
}

# =============================================================================
# MICROSOFT DEFENDER FOR CLOUD
# =============================================================================

variable "enable_defender" {
  description = "Enable Microsoft Defender for Cloud (Security posture)"
  type        = bool
  default     = true
}

variable "defender_plans" {
  description = "Defender plans to enable with pricing tier"
  type = map(object({
    tier    = string # Free or Standard
    enabled = bool
  }))
  default = {
    "VirtualMachines" = {
      tier    = "Standard"
      enabled = true
    }
    "SqlServers" = {
      tier    = "Standard"
      enabled = true
    }
    "AppServices" = {
      tier    = "Standard"
      enabled = true
    }
    "StorageAccounts" = {
      tier    = "Standard"
      enabled = true
    }
    "KeyVaults" = {
      tier    = "Standard"
      enabled = true
    }
    "KubernetesService" = {
      tier    = "Free" # Cost optimization
      enabled = false
    }
  }
}

# =============================================================================
# BACKUP & DISASTER RECOVERY
# =============================================================================

variable "enable_backup_vault" {
  description = "Deploy Azure Backup (Recovery Services Vault)"
  type        = bool
  default     = true
}

variable "backup_policy_vm" {
  description = "VM backup policy configuration"
  type = object({
    frequency         = string
    time              = string
    retention_daily   = number
    retention_weekly  = number
    retention_monthly = number
    retention_yearly  = number
  })
  default = {
    frequency         = "Daily"
    time              = "23:00"
    retention_daily   = 30
    retention_weekly  = 12
    retention_monthly = 12
    retention_yearly  = 7
  }
}

# =============================================================================
# COST MANAGEMENT
# =============================================================================

variable "enable_cost_management" {
  description = "Enable Azure Cost Management + Billing"
  type        = bool
  default     = true
}

variable "enable_budgets" {
  description = "Create cost budgets with alerts"
  type        = bool
  default     = true
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD for entire customer deployment"
  type        = number
  default     = 0 # 0 = no limit
}

variable "budget_alert_thresholds" {
  description = "Budget alert thresholds (percentage of budget)"
  type        = list(number)
  default     = [80, 100, 120]
}

# =============================================================================
# RBAC & ACCESS CONTROL
# =============================================================================

variable "enable_rbac_assignments" {
  description = "Configure RBAC for centralized management"
  type        = bool
  default     = true
}

variable "management_read_only_groups" {
  description = "Azure AD groups with read-only access to Management subscription"
  type        = list(string)
  default     = []
}

variable "log_analytics_readers" {
  description = "Azure AD groups/users with LAW read access (from your diagram)"
  type        = map(list(string))
  default = {
    "operations" = [] # TeamA-Operations read access
    "security"   = [] # TeamA-Security read access
    "audit"      = [] # TeamB-Audit read access
  }
}

# =============================================================================
# DATA EXPORT & INTEGRATION
# =============================================================================

variable "enable_log_export" {
  description = "Export logs to Storage Account for long-term retention"
  type        = bool
  default     = true
}

variable "log_export_retention_days" {
  description = "Storage account retention for exported logs (cheaper than LAW)"
  type        = number
  default     = 2555 # 7 years in blob storage (compliance)
}

variable "enable_event_hub_export" {
  description = "Export logs to Event Hub for SIEM integration"
  type        = bool
  default     = false
}

# =============================================================================
# TAGGING STRATEGY
# =============================================================================

variable "tags" {
  description = "Common tags to apply to all management resources"
  type        = map(string)
  default     = {}
}

variable "mandatory_tags" {
  description = "Mandatory tags that cannot be overridden"
  type        = map(string)
  default     = {}
}

# =============================================================================
# COST OPTIMIZATION
# =============================================================================

variable "enable_commitment_tiers" {
  description = "Use commitment tiers for LAW (save 15-30% for predictable usage)"
  type        = bool
  default     = false
}

variable "commitment_tier_gb" {
  description = "Commitment tier in GB/day (100, 200, 300, 400, 500, 1000, 2000, 5000)"
  type        = number
  default     = 100
  validation {
    condition     = contains([100, 200, 300, 400, 500, 1000, 2000, 5000], var.commitment_tier_gb)
    error_message = "Must be valid commitment tier: 100, 200, 300, 400, 500, 1000, 2000, 5000."
  }
}

variable "enable_basic_logs" {
  description = "Use Basic logs tier for high-volume, low-query logs (80% cost savings)"
  type        = bool
  default     = true
}

variable "basic_log_tables" {
  description = "Tables to configure as Basic logs (8-day retention, limited queries)"
  type        = list(string)
  default = [
    "ContainerLog",
    "AppServiceConsoleLogs",
    "AppServiceHTTPLogs"
  ]
}
# =============================================================================
# MULTI-WORKSPACE LOGGING VARIABLES (Add to existing file)
# =============================================================================

variable "spoke_workspaces" {
  description = "Per-spoke Log Analytics Workspaces configuration"
  type = map(object({
    retention_days = number
    daily_quota_gb = number
    cost_center    = string
  }))
  default = {
    "production" = {
      retention_days = 90
      daily_quota_gb = 50
      cost_center    = "Production-Workloads"
    }
    "development" = {
      retention_days = 30
      daily_quota_gb = 10
      cost_center    = "Development"
    }
    "staging" = {
      retention_days = 60
      daily_quota_gb = 20
      cost_center    = "Staging"
    }
  }
}

variable "enable_audit_workspace" {
  description = "Enable dedicated audit workspace with 7-year retention"
  type        = bool
  default     = true
}

variable "audit_workspace_daily_quota_gb" {
  description = "Daily quota for audit workspace (GB)"
  type        = number
  default     = 20
}

variable "enable_log_forwarding" {
  description = "Enable automatic log forwarding from spoke to central workspace"
  type        = bool
  default     = true
}