# =============================================================================
# EVENT HUB MODULE VARIABLES
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

variable "eventhub_namespace_name" {
  type    = string
  default = null
}

variable "sku" {
  type    = string
  default = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "Must be Basic, Standard, or Premium."
  }
}

variable "capacity" {
  description = "Throughput units (1-40 for Standard, 1-100 for Premium)"
  type        = number
  default     = 1
}

variable "enable_auto_inflate" {
  type    = bool
  default = false
}

variable "maximum_throughput_units" {
  type    = number
  default = 20
}

variable "enable_zone_redundancy" {
  type    = bool
  default = false
}

variable "enable_kafka" {
  type    = bool
  default = true
}

variable "public_network_access_enabled" {
  type    = bool
  default = false
}

variable "allowed_ip_ranges" {
  type    = list(string)
  default = []
}

variable "allowed_subnet_ids" {
  type    = list(string)
  default = []
}

variable "event_hubs" {
  description = "Event Hubs to create"
  type = map(object({
    partition_count                = number
    message_retention_days         = number
    enable_capture                 = bool
    capture_encoding               = string
    capture_interval_seconds       = number
    capture_size_limit_bytes       = number
    capture_skip_empty_archives    = bool
    capture_name_format            = string
    capture_container_name         = string
    capture_storage_account_id     = string
  }))
  default = {}
}

variable "consumer_groups" {
  type = map(object({
    eventhub_name = string
    user_metadata = string
  }))
  default = {}
}

variable "namespace_authorization_rules" {
  type = map(object({
    listen = bool
    send   = bool
    manage = bool
  }))
  default = {}
}

variable "enable_private_endpoint" {
  type    = bool
  default = true
}

variable "subnet_id" {
  type    = string
  default = null
}

variable "private_dns_zone_id" {
  type    = string
  default = null
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "cost_center" {
  type    = string
  default = "Event-Streaming"
}

variable "team" {
  type    = string
  default = "Platform"
}

variable "tags" {
  type    = map(string)
  default = {}
}