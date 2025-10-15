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
  description = "Private subnet ID"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for privatelink.vaultcore.azure.net"
  type        = string
}

variable "log_analytics_workspace_id" {
  type = string
}

# =============================================================================
# KEY VAULT CONFIGURATION
# =============================================================================

variable "keyvault_name" {
  description = "Key Vault name (leave null for auto-generated)"
  type        = string
  default     = null
}

variable "sku_name" {
  description = "SKU: standard or premium (HSM)"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "Must be standard or premium."
  }
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention (7-90 days)"
  type        = number
  default     = 90
}

variable "purge_protection_enabled" {
  description = "Enable purge protection (cannot be disabled once enabled)"
  type        = bool
  default     = true
}

variable "enable_rbac_authorization" {
  description = "Use RBAC instead of access policies"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Allow public access"
  type        = bool
  default     = false
}

# =============================================================================
# ACCESS POLICIES (if RBAC disabled)
# =============================================================================

variable "access_policies" {
  description = "Access policies for Key Vault (if not using RBAC)"
  type = map(object({
    object_id          = string
    key_permissions    = list(string)
    secret_permissions = list(string)
    certificate_permissions = list(string)
  }))
  default = {}
}

# =============================================================================
# NETWORK RULES
# =============================================================================

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for Key Vault access"
  type        = list(string)
  default     = []
}

variable "bypass_azure_services" {
  description = "Allow Azure services to bypass firewall"
  type        = bool
  default     = true
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