# =============================================================================
# MANAGEMENT DEPLOYMENT - Calls Management Module
# =============================================================================
# Deploy this FIRST (before Hub and Spokes)

module "management" {
  source = "../../../modules/management"
  
  # Identity
  customer_id = var.customer_id
  environment = var.environment
  region      = var.region
  region_code = var.region_code
  
  # Central Log Analytics
  enable_central_law         = true
  central_law_retention_days = 90
  central_law_daily_quota_gb = 50
  
  enable_team_workspaces = true
  team_workspaces = {
    "operations" = {
      retention_days = 90
      daily_quota_gb = 30
      purpose        = "Operational logs"
    }
    "security" = {
      retention_days = 730
      daily_quota_gb = 50
      purpose        = "Security logs"
    }
  }
  
  # Cost allocation
  enable_cost_splitting = true
  cost_allocation_tags = {
    "spoke-prod" = {
      cost_center    = "Production-Workloads"
      team           = "TeamA"
      chargeback     = true
      budget_alert   = 50000
    }
    "spoke-dev" = {
      cost_center    = "Development"
      team           = "TeamB"
      chargeback     = false
      budget_alert   = 10000
    }
  }
  
  # Long-term archival (FIXED - max 365 days for blob storage)
  enable_log_export         = true
  log_export_retention_days = 365
  
  # Monitoring & Alerts
  enable_action_groups   = true
  enable_kql_alert_rules = true
  alert_email_receivers  = ["shanumodi9@gmail.com"]
  
  # Security
  enable_azure_policy = true
  enable_defender     = true
  defender_plans = {
    "VirtualMachines"  = { tier = "Standard", enabled = true }
    "SqlServers"       = { tier = "Standard", enabled = true }
    "StorageAccounts"  = { tier = "Standard", enabled = true }
    "KeyVaults"        = { tier = "Standard", enabled = true }
  }
  
  # Backup
  enable_backup_vault = true
  
  # Cost Management (disabled to avoid budget errors)
  enable_budgets       = false
  monthly_budget_limit = 0
  
  tags = {
    Project = "CAF-LZ-Management"
  }
}

# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------

output "central_workspace_id" {
  description = "Central LAW ID (Used by Hub and Spokes)"
  value       = module.management.central_workspace_id
}

output "central_workspace_name" {
  value = module.management.central_workspace_name
}

output "action_group_id" {
  value = module.management.action_group_id
}

output "backup_vault_id" {
  value = module.management.backup_vault_id
}