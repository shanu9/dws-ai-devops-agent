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
  
  # Team workspaces (from your diagram)
  enable_team_workspaces = true
  team_workspaces = {
    "operations" = {
      retention_days = 90
      daily_quota_gb = 30
      purpose        = "Operational logs"
    }
    "security" = {
      retention_days = 730  # 2 years
      daily_quota_gb = 50
      purpose        = "Security logs"
    }
    "audit" = {
      retention_days = 2555  # 7 years
      daily_quota_gb = 20
      purpose        = "Audit logs"
    }
  }
  
  # Cost allocation (per spoke)
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
  
  # Long-term archival
  enable_log_export         = true
  log_export_retention_days = 2555  # 7 years in blob storage
  
  # Monitoring & Alerts
  enable_action_groups   = true
  enable_kql_alert_rules = true
  alert_email_receivers  = var.alert_emails
  
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
  
  # Cost Management
  enable_budgets       = true
  monthly_budget_limit = var.monthly_budget
  
  tags = {
    Project = "CAF-LZ-Management"
  }
}

# -----------------------------------------------------------------------------
# OUTPUTS (for Hub and Spoke consumption)
# -----------------------------------------------------------------------------

output "central_workspace_id" {
  description = "Central LAW ID (CRITICAL: Used by all modules)"
  value       = module.management.central_workspace_id
}

output "central_workspace_name" {
  value = module.management.central_workspace_name
}

output "team_workspace_ids" {
  value     = module.management.team_workspace_ids
  sensitive = true
}

output "action_group_id" {
  value = module.management.action_group_id
}

output "backup_vault_id" {
  value = module.management.backup_vault_id
}