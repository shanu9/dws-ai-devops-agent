# =============================================================================
# COGNITIVE SEARCH MODULE VARIABLES
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

variable "search_service_name" {
  description = "Search service name (auto-generated if not provided)"
  type        = string
  default     = null
}

variable "search_sku" {
  description = "Search service SKU"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["free", "basic", "standard", "standard2", "standard3", "storage_optimized_l1", "storage_optimized_l2"], var.search_sku)
    error_message = "Must be a valid Search SKU."
  }
}

variable "replica_count" {
  description = "Number of replicas (high availability)"
  type        = number
  default     = 1
  validation {
    condition     = var.replica_count >= 1 && var.replica_count <= 12
    error_message = "Must be between 1 and 12."
  }
}

variable "partition_count" {
  description = "Number of partitions (storage and throughput)"
  type        = number
  default     = 1
  validation {
    condition     = contains([1, 2, 3, 4, 6, 12], var.partition_count)
    error_message = "Must be 1, 2, 3, 4, 6, or 12."
  }
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges (if public access enabled)"
  type        = list(string)
  default     = []
}

variable "enable_semantic_search" {
  description = "Enable semantic search (AI-powered relevance)"
  type        = bool
  default     = false
}

variable "semantic_search_sku" {
  description = "Semantic search SKU"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["free", "standard"], var.semantic_search_sku)
    error_message = "Must be free or standard."
  }
}

variable "enable_local_authentication" {
  description = "Enable API key authentication"
  type        = bool
  default     = true
}

variable "authentication_failure_mode" {
  description = "Authentication failure mode"
  type        = string
  default     = "http401WithBearerChallenge"
  validation {
    condition     = contains(["http401WithBearerChallenge", "http403"], var.authentication_failure_mode)
    error_message = "Must be http401WithBearerChallenge or http403."
  }
}

variable "enable_customer_managed_key" {
  description = "Enable customer-managed key encryption"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "Create private endpoint"
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for Cognitive Search"
  type        = string
  default     = null
}

variable "private_link_resources" {
  description = "Private link resources for indexers to access data sources"
  type = map(object({
    resource_id       = string
    subresource_name  = string
    request_message   = string
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Search-Platform"
}

variable "team" {
  description = "Team responsible"
  type        = string
  default     = "Data-Platform"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}