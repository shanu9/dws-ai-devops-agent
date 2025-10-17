# =============================================================================
# PURVIEW MODULE VARIABLES
# =============================================================================

variable "customer_id" {
  description = "Unique customer identifier"
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
  description = "Short region code"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "purview_account_name" {
  description = "Purview account name (auto-generated if not provided)"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "managed_resource_group_name" {
  description = "Managed resource group name (auto-generated if not provided)"
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Create private endpoints"
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
  default     = null
}

variable "private_dns_zone_id_account" {
  description = "Private DNS zone ID for Purview account"
  type        = string
  default     = null
}

variable "private_dns_zone_id_portal" {
  description = "Private DNS zone ID for Purview portal"
  type        = string
  default     = null
}

variable "storage_account_ids" {
  description = "List of storage account IDs to grant Purview access"
  type        = list(string)
  default     = []
}

variable "sql_server_ids" {
  description = "List of SQL server IDs to grant Purview access"
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "cost_center" {
  description = "Cost center"
  type        = string
  default     = "Data-Governance"
}

variable "team" {
  description = "Team"
  type        = string
  default     = "Data-Governance"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}