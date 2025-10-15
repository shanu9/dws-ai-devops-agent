# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "customer_id" {
  description = "Customer identifier"
  type        = string
}

variable "environment" {
  description = "Environment (dev/stg/prd)"
  type        = string
}

variable "spoke_name" {
  description = "Spoke name"
  type        = string
}

variable "region" {
  description = "Azure region"
  type        = string
}

variable "region_code" {
  description = "Region code"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name (from Spoke)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint (from Spoke private subnet)"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for privatelink.database.windows.net"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}

# =============================================================================
# SQL SERVER CONFIGURATION
# =============================================================================

variable "sql_server_name" {
  description = "SQL Server name (leave null for auto-generated)"
  type        = string
  default     = null
}

variable "administrator_login" {
  description = "SQL admin username"
  type        = string
  default     = "sqladmin"
}

variable "administrator_password" {
  description = "SQL admin password (use Azure Key Vault in production)"
  type        = string
  sensitive   = true
}

variable "sql_version" {
  description = "SQL Server version"
  type        = string
  default     = "12.0"
}

variable "enable_azure_ad_authentication" {
  description = "Enable Azure AD authentication"
  type        = bool
  default     = true
}

variable "azuread_administrator" {
  description = "Azure AD admin configuration"
  type = object({
    login_username = string
    object_id      = string
  })
  default = null
}

# =============================================================================
# SQL DATABASE CONFIGURATION
# =============================================================================

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "sku_name" {
  description = "Database SKU (GP_S_Gen5_2, BC_Gen5_4, etc.)"
  type        = string
  default     = "GP_S_Gen5_2" # Serverless Gen5, 2 vCores
}

variable "max_size_gb" {
  description = "Max database size in GB"
  type        = number
  default     = 32
}

variable "min_capacity" {
  description = "Min vCores for serverless (cost optimization)"
  type        = number
  default     = 0.5
}

variable "auto_pause_delay_in_minutes" {
  description = "Auto-pause delay (serverless cost optimization)"
  type        = number
  default     = 60
}

variable "zone_redundant" {
  description = "Enable zone redundancy"
  type        = bool
  default     = false
}

variable "read_replica_count" {
  description = "Number of read replicas"
  type        = number
  default     = 0
}

# =============================================================================
# BACKUP & RETENTION
# =============================================================================

variable "backup_retention_days" {
  description = "Backup retention period (7-35 days)"
  type        = number
  default     = 7
}

variable "long_term_retention_policy" {
  description = "Long-term backup retention"
  type = object({
    weekly_retention  = string
    monthly_retention = string
    yearly_retention  = string
    week_of_year      = number
  })
  default = {
    weekly_retention  = "P4W"  # 4 weeks
    monthly_retention = "P12M" # 12 months
    yearly_retention  = "P7Y"  # 7 years
    week_of_year      = 1
  }
}

# =============================================================================
# SECURITY
# =============================================================================

variable "enable_threat_detection" {
  description = "Enable Advanced Threat Protection"
  type        = bool
  default     = true
}

variable "enable_vulnerability_assessment" {
  description = "Enable SQL Vulnerability Assessment"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Allow public network access (set false for private only)"
  type        = bool
  default     = false
}

variable "enable_transparent_data_encryption" {
  description = "Enable TDE"
  type        = bool
  default     = true
}

# =============================================================================
# TAGS
# =============================================================================

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "cost_center" {
  description = "Cost center"
  type        = string
}

variable "team" {
  description = "Team name"
  type        = string
}