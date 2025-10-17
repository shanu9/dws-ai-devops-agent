# =============================================================================
# COSMOS DB MODULE VARIABLES
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

# -----------------------------------------------------------------------------
# COSMOS DB ACCOUNT CONFIGURATION
# -----------------------------------------------------------------------------

variable "cosmos_account_name" {
  description = "Cosmos DB account name (auto-generated if not provided)"
  type        = string
  default     = null
}

variable "cosmos_db_kind" {
  description = "Cosmos DB API kind"
  type        = string
  default     = "GlobalDocumentDB" # SQL API
  validation {
    condition = contains([
      "GlobalDocumentDB", # SQL API
      "MongoDB",
      "Parse"            # Deprecated
    ], var.cosmos_db_kind)
    error_message = "Must be GlobalDocumentDB or MongoDB."
  }
}

# -----------------------------------------------------------------------------
# CONSISTENCY CONFIGURATION
# -----------------------------------------------------------------------------

variable "consistency_level" {
  description = "Default consistency level"
  type        = string
  default     = "Session" # Best balance
  validation {
    condition = contains([
      "Strong",           # Highest consistency, highest latency
      "BoundedStaleness", # Configurable staleness
      "Session",          # Best for single client (default)
      "ConsistentPrefix", # Reads never see out-of-order writes
      "Eventual"          # Lowest latency, eventual consistency
    ], var.consistency_level)
    error_message = "Must be a valid consistency level."
  }
}

variable "max_staleness_interval" {
  description = "Max lag time in seconds (BoundedStaleness only)"
  type        = number
  default     = 5
  validation {
    condition     = var.max_staleness_interval >= 5 && var.max_staleness_interval <= 86400
    error_message = "Must be between 5 and 86400 seconds."
  }
}

variable "max_staleness_prefix" {
  description = "Max lag in operations (BoundedStaleness only)"
  type        = number
  default     = 100
  validation {
    condition     = var.max_staleness_prefix >= 10 && var.max_staleness_prefix <= 2147483647
    error_message = "Must be between 10 and 2147483647."
  }
}

# -----------------------------------------------------------------------------
# GEO-REPLICATION
# -----------------------------------------------------------------------------

variable "failover_locations" {
  description = "Additional regions for geo-replication"
  type = list(object({
    location       = string
    priority       = number
    zone_redundant = bool
  }))
  default = []
  # Example:
  # [
  #   {
  #     location       = "westus"
  #     priority       = 1
  #     zone_redundant = true
  #   }
  # ]
}

variable "enable_zone_redundancy" {
  description = "Enable zone redundancy for primary region"
  type        = bool
  default     = true
}

variable "enable_automatic_failover" {
  description = "Enable automatic failover to secondary regions"
  type        = bool
  default     = true
}

variable "enable_multiple_write_locations" {
  description = "Enable multi-region writes (expensive)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# CAPABILITIES
# -----------------------------------------------------------------------------

variable "capabilities" {
  description = "Cosmos DB capabilities"
  type        = list(string)
  default     = []
  # Common capabilities:
  # - "EnableServerless"       # Serverless mode (pay per request)
  # - "EnableCassandra"        # Cassandra API
  # - "EnableGremlin"          # Gremlin (Graph) API
  # - "EnableTable"            # Table API
  # - "EnableMongo"            # MongoDB API
  # - "EnableAggregationPipeline"
  # - "mongoEnableDocLevelTTL"
}

# -----------------------------------------------------------------------------
# BACKUP CONFIGURATION
# -----------------------------------------------------------------------------

variable "backup_type" {
  description = "Backup type (Periodic or Continuous)"
  type        = string
  default     = "Periodic"
  validation {
    condition     = contains(["Periodic", "Continuous"], var.backup_type)
    error_message = "Must be Periodic or Continuous."
  }
}

variable "backup_interval_minutes" {
  description = "Backup interval in minutes (Periodic only)"
  type        = number
  default     = 240 # 4 hours
  validation {
    condition     = var.backup_interval_minutes >= 60 && var.backup_interval_minutes <= 1440
    error_message = "Must be between 60 (1 hour) and 1440 (24 hours)."
  }
}

variable "backup_retention_hours" {
  description = "Backup retention in hours (Periodic only)"
  type        = number
  default     = 720 # 30 days
  validation {
    condition     = var.backup_retention_hours >= 8 && var.backup_retention_hours <= 720
    error_message = "Must be between 8 hours and 720 hours (30 days)."
  }
}

variable "backup_storage_redundancy" {
  description = "Backup storage redundancy"
  type        = string
  default     = "Geo"
  validation {
    condition     = contains(["Geo", "Local", "Zone"], var.backup_storage_redundancy)
    error_message = "Must be Geo, Local, or Zone."
  }
}

# -----------------------------------------------------------------------------
# NETWORK CONFIGURATION
# -----------------------------------------------------------------------------

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "enable_vnet_filter" {
  description = "Enable virtual network filter"
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Subnet ID for service endpoint/private endpoint"
  type        = string
  default     = null
}

variable "ip_range_filter" {
  description = "IP addresses/ranges allowed (if public access enabled)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT
# -----------------------------------------------------------------------------

variable "enable_private_endpoint" {
  description = "Create private endpoint"
  type        = bool
  default     = true
}

variable "private_endpoint_subresource" {
  description = "Private endpoint subresource"
  type        = string
  default     = "Sql" # Sql, MongoDB, Cassandra, Gremlin, Table
  validation {
    condition     = contains(["Sql", "MongoDB", "Cassandra", "Gremlin", "Table"], var.private_endpoint_subresource)
    error_message = "Must be Sql, MongoDB, Cassandra, Gremlin, or Table."
  }
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for Cosmos DB"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# SQL API DATABASES & CONTAINERS
# -----------------------------------------------------------------------------

variable "sql_databases" {
  description = "SQL API databases to create"
  type = map(object({
    throughput         = number
    autoscale_enabled  = bool
    max_throughput     = number
  }))
  default = {}
  # Example:
  # {
  #   "products-db" = {
  #     throughput        = 400
  #     autoscale_enabled = false
  #     max_throughput    = 4000
  #   }
  # }
}

variable "sql_containers" {
  description = "SQL API containers to create"
  type = map(object({
    database_name           = string
    container_name          = string
    partition_key_path      = string
    throughput              = number
    autoscale_enabled       = bool
    max_throughput          = number
    indexing_mode           = string
    included_paths          = list(string)
    excluded_paths          = list(string)
    default_ttl             = number
    analytical_storage_ttl  = number
    unique_keys             = list(list(string))
  }))
  default = {}
  # Example:
  # {
  #   "products-container" = {
  #     database_name          = "products-db"
  #     container_name         = "products"
  #     partition_key_path     = "/categoryId"
  #     throughput             = 400
  #     autoscale_enabled      = false
  #     max_throughput         = 4000
  #     indexing_mode          = "consistent"
  #     included_paths         = ["/*"]
  #     excluded_paths         = ["/metadata/*"]
  #     default_ttl            = -1
  #     analytical_storage_ttl = -1
  #     unique_keys            = [["/productId"]]
  #   }
  # }
}

# -----------------------------------------------------------------------------
# MONGODB API DATABASES & COLLECTIONS
# -----------------------------------------------------------------------------

variable "mongo_databases" {
  description = "MongoDB API databases to create"
  type = map(object({
    throughput        = number
    autoscale_enabled = bool
    max_throughput    = number
  }))
  default = {}
}

variable "mongo_collections" {
  description = "MongoDB API collections to create"
  type = map(object({
    database_name     = string
    collection_name   = string
    shard_key         = string
    throughput        = number
    autoscale_enabled = bool
    max_throughput    = number
    indexes = list(object({
      keys   = list(string)
      unique = bool
    }))
    default_ttl = number
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# ADVANCED FEATURES
# -----------------------------------------------------------------------------

variable "enable_analytical_storage" {
  description = "Enable analytical storage (for Synapse Link)"
  type        = bool
  default     = false
}

variable "enable_free_tier" {
  description = "Enable free tier (one per subscription, 400 RU/s, 5GB)"
  type        = bool
  default     = false
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
  default     = "NoSQL-Database"
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