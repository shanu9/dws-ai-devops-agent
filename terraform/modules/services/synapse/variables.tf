# =============================================================================
# SYNAPSE MODULE VARIABLES
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "customer_id" {
  description = "Unique customer identifier"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,6}$", var.customer_id))
    error_message = "Customer ID must be 3-6 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment (dev/stg/prd)"
  type        = string
  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "Environment must be dev, stg, or prd."
  }
}

variable "spoke_name" {
  description = "Spoke name (e.g., production, development)"
  type        = string
}

variable "region" {
  description = "Azure region"
  type        = string
}

variable "region_code" {
  description = "Short region code (e.g., eus, wus)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "sql_admin_username" {
  description = "SQL administrator username"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "SQL administrator password"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# SYNAPSE WORKSPACE CONFIGURATION
# -----------------------------------------------------------------------------

variable "synapse_workspace_name" {
  description = "Synapse workspace name (auto-generated if not provided)"
  type        = string
  default     = null
}

variable "enable_managed_vnet" {
  description = "Enable managed virtual network (recommended)"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "enable_data_exfiltration_protection" {
  description = "Enable data exfiltration protection"
  type        = bool
  default     = true
}

variable "storage_replication_type" {
  description = "Storage replication type for workspace storage"
  type        = string
  default     = "GRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.storage_replication_type)
    error_message = "Must be LRS, GRS, RAGRS, or ZRS."
  }
}

variable "aad_admin" {
  description = "Azure AD administrator for Synapse"
  type = object({
    login     = string
    object_id = string
    tenant_id = string
  })
  default = null
}

# -----------------------------------------------------------------------------
# SQL POOL CONFIGURATION (Dedicated - High Cost!)
# -----------------------------------------------------------------------------

variable "enable_sql_pool" {
  description = "Create dedicated SQL pool (expensive - $1000+/month)"
  type        = bool
  default     = false
}

variable "sql_pool_name" {
  description = "SQL pool name (auto-generated if not provided)"
  type        = string
  default     = null
}

variable "sql_pool_sku" {
  description = "SQL pool SKU (DW100c, DW200c, etc.)"
  type        = string
  default     = "DW100c" # Smallest size for cost optimization
  validation {
    condition     = can(regex("^DW[0-9]+c$", var.sql_pool_sku))
    error_message = "SKU must be in format DW100c, DW200c, etc."
  }
}

variable "sql_pool_auto_pause_delay" {
  description = "Auto-pause delay in minutes (cost optimization)"
  type        = number
  default     = 60
}

variable "enable_sql_pool_autoscale" {
  description = "Enable SQL pool auto-scale"
  type        = bool
  default     = false
}

variable "sql_pool_min_size_gb" {
  description = "Minimum SQL pool size in GB"
  type        = number
  default     = 100
}

variable "sql_pool_max_size_gb" {
  description = "Maximum SQL pool size in GB"
  type        = number
  default     = 1024
}

# -----------------------------------------------------------------------------
# SPARK POOL CONFIGURATION
# -----------------------------------------------------------------------------

variable "enable_spark_pool" {
  description = "Create Apache Spark pool"
  type        = bool
  default     = true
}

variable "spark_pool_name" {
  description = "Spark pool name (auto-generated if not provided)"
  type        = string
  default     = null
}

variable "spark_node_size" {
  description = "Spark node size (Small, Medium, Large, XLarge, XXLarge)"
  type        = string
  default     = "Small" # Cost optimization
  validation {
    condition     = contains(["Small", "Medium", "Large", "XLarge", "XXLarge"], var.spark_node_size)
    error_message = "Must be Small, Medium, Large, XLarge, or XXLarge."
  }
}

variable "spark_node_count_min" {
  description = "Minimum number of Spark nodes"
  type        = number
  default     = 3
  validation {
    condition     = var.spark_node_count_min >= 3
    error_message = "Minimum is 3 nodes."
  }
}

variable "spark_node_count_max" {
  description = "Maximum number of Spark nodes (if autoscale enabled)"
  type        = number
  default     = 10
}

variable "enable_spark_autoscale" {
  description = "Enable Spark pool auto-scale"
  type        = bool
  default     = true
}

variable "spark_auto_pause_delay" {
  description = "Spark auto-pause delay in minutes (cost optimization)"
  type        = number
  default     = 15
}

variable "spark_version" {
  description = "Spark version"
  type        = string
  default     = "3.4"
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT CONFIGURATION
# -----------------------------------------------------------------------------

variable "enable_private_endpoint" {
  description = "Create private endpoints"
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id_sql" {
  description = "Private DNS zone ID for Synapse SQL endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id_dev" {
  description = "Private DNS zone ID for Synapse Dev endpoint"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# FIREWALL RULES
# -----------------------------------------------------------------------------

variable "firewall_rules" {
  description = "Firewall rules (if public access enabled)"
  type = map(object({
    start_ip = string
    end_ip   = string
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# MONITORING & DIAGNOSTICS
# -----------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# COST ALLOCATION
# -----------------------------------------------------------------------------

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Data-Warehouse"
}

variable "team" {
  description = "Team responsible for the resource"
  type        = string
  default     = "Data-Platform"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}