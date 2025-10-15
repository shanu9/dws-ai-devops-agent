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

variable "private_dns_zone_ids" {
  description = "Map of private DNS zone IDs (blob, file, dfs, table, queue)"
  type        = map(string)
}

variable "log_analytics_workspace_id" {
  type = string
}

# =============================================================================
# STORAGE ACCOUNT CONFIGURATION
# =============================================================================

variable "storage_account_name" {
  description = "Storage account name (3-24 chars, lowercase alphanumeric)"
  type        = string
  default     = null
}

variable "account_tier" {
  description = "Storage tier: Standard or Premium"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Replication: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS"
  type        = string
  default     = "GRS"
}

variable "account_kind" {
  description = "Account kind: StorageV2, BlobStorage, BlockBlobStorage"
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Access tier: Hot or Cool"
  type        = string
  default     = "Hot"
}

variable "enable_hierarchical_namespace" {
  description = "Enable Data Lake Gen2 (ADLS)"
  type        = bool
  default     = true
}

variable "is_hns_migration_enabled" {
  description = "Enable HNS migration"
  type        = bool
  default     = false
}

# =============================================================================
# SECURITY
# =============================================================================

variable "enable_https_traffic_only" {
  type    = bool
  default = true
}

variable "min_tls_version" {
  type    = string
  default = "TLS1_2"
}

variable "allow_nested_items_to_be_public" {
  type    = bool
  default = false
}

variable "shared_access_key_enabled" {
  type    = bool
  default = false
}

variable "public_network_access_enabled" {
  type    = bool
  default = false
}

variable "default_to_oauth_authentication" {
  type    = bool
  default = true
}

# =============================================================================
# BLOB PROPERTIES
# =============================================================================

variable "enable_versioning" {
  type    = bool
  default = true
}

variable "change_feed_enabled" {
  type    = bool
  default = true
}

variable "delete_retention_days" {
  description = "Blob soft delete retention (1-365 days)"
  type        = number
  default     = 30
}

variable "container_delete_retention_days" {
  type    = number
  default = 30
}

# =============================================================================
# LIFECYCLE MANAGEMENT
# =============================================================================

variable "enable_lifecycle_management" {
  type    = bool
  default = true
}

variable "lifecycle_rules" {
  description = "Lifecycle management rules"
  type = map(object({
    enabled                                    = bool
    blob_types                                 = list(string)
    prefix_match                               = list(string)
    tier_to_cool_after_days                    = number
    tier_to_archive_after_days                 = number
    delete_after_days                          = number
  }))
  default = {
    "default" = {
      enabled                     = true
      blob_types                  = ["blockBlob"]
      prefix_match                = []
      tier_to_cool_after_days     = 30
      tier_to_archive_after_days  = 90
      delete_after_days           = 365
    }
  }
}

# =============================================================================
# CONTAINERS
# =============================================================================

variable "containers" {
  description = "Blob containers to create"
  type = map(object({
    container_access_type = string
  }))
  default = {
    "raw"       = { container_access_type = "private" }
    "processed" = { container_access_type = "private" }
    "archive"   = { container_access_type = "private" }
  }
}

# =============================================================================
# PRIVATE ENDPOINTS
# =============================================================================

variable "enable_blob_private_endpoint" {
  type    = bool
  default = true
}

variable "enable_dfs_private_endpoint" {
  type    = bool
  default = true
}

variable "enable_file_private_endpoint" {
  type    = bool
  default = false
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