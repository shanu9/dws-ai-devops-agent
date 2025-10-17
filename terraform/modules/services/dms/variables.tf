# =============================================================================
# DMS MODULE VARIABLES
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

variable "dms_name" {
  type    = string
  default = null
}

variable "sku_name" {
  description = "SKU name (Standard_1vCore, Standard_2vCores, Standard_4vCores, Premium_4vCores)"
  type        = string
  default     = "Standard_1vCore"
  validation {
    condition = contains([
      "Standard_1vCore", "Standard_2vCores", "Standard_4vCores", 
      "Premium_4vCores", "Premium_8vCores"
    ], var.sku_name)
    error_message = "Must be valid DMS SKU."
  }
}

variable "subnet_id" {
  description = "Subnet ID for DMS service"
  type        = string
}

variable "migration_projects" {
  description = "Migration projects to create"
  type = map(object({
    source_platform = string
    target_platform = string
  }))
  default = {}
  # Example:
  # {
  #   "sql-to-azure" = {
  #     source_platform = "SQL"
  #     target_platform = "SQLDB"
  #   }
  # }
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "cost_center" {
  type    = string
  default = "Database-Migration"
}

variable "team" {
  type    = string
  default = "Database"
}

variable "tags" {
  type    = map(string)
  default = {}
}