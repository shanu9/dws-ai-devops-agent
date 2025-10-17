# Customer-specific variables (values in terraform.tfvars)

variable "customer_id" {
  description = "Customer identifier (3-6 chars)"
  type        = string
}

variable "environment" {
  description = "Environment: dev/stg/prd"
  type        = string
  default     = "prd"
}

variable "region" {
  description = "Azure region"
  type        = string
}

variable "region_code" {
  description = "Region code (eus, jpe, etc.)"
  type        = string
}

variable "hub_vnet_cidr" {
  description = "Hub VNet CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "firewall_sku" {
  description = "Firewall SKU: Standard or Premium"
  type        = string
  default     = "Standard"
}

variable "enable_bastion" {
  type    = bool
  default = true
}

variable "enable_vpn_gateway" {
  type    = bool
  default = false
}

variable "alert_email" {
  description = "Email for alerts"
  type        = string
}