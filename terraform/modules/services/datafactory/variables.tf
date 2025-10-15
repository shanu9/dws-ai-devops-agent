# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "customer_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "spoke_name" {
  type = string
}

variable "region" {
  type = string
}

variable "region_code" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for privatelink.datafactory.azure.net"
  type        = string
}

variable "log_analytics_workspace_id" {
  type = string
}

# =============================================================================
# DATA FACTORY CONFIGURATION
# =============================================================================

variable "data_factory_name" {
  description = "Data Factory name (leave null for auto-generated)"
  type        = string
  default     = null
}

variable "public_network_enabled" {
  type    = bool
  default = false
}

variable "managed_virtual_network_enabled" {
  description = "Enable managed VNet for integration runtime"
  type        = bool
  default     = true
}

variable "customer_managed_key_id" {
  description = "Key Vault key ID for encryption"
  type        = string
  default     = null
}

# =============================================================================
# INTEGRATION RUNTIME
# =============================================================================

variable "enable_azure_ir" {
  description = "Create Azure Integration Runtime"
  type        = bool
  default     = true
}

variable "azure_ir_compute_type" {
  type    = string
  default = "General"
}

variable "azure_ir_core_count" {
  type    = number
  default = 8
}

variable "azure_ir_time_to_live" {
  description = "TTL in minutes (cost optimization)"
  type        = number
  default     = 10
}

# =============================================================================
# GIT CONFIGURATION
# =============================================================================

variable "enable_git_integration" {
  type    = bool
  default = false
}

variable "git_config" {
  type = object({
    account_name    = string
    branch_name     = string
    repository_name = string
    root_folder     = string
    type            = string # GitHub or AzureDevOps
  })
  default = null
}

# =============================================================================
# TAGS
# =============================================================================

variable "tags" {
  type    = map(string)
  default = {}
}

variable "cost_center" {
  type = string
}

variable "team" {
  type = string
}