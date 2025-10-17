variable "customer_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "region_code" {
  type = string
}

variable "hub_vnet_cidr" {
  type = string
}

variable "firewall_sku" {
  type = string
}

variable "enable_bastion" {
  type = bool
}

variable "enable_vpn_gateway" {
  type = bool
}

# Backend configuration
variable "state_storage_account_name" {
  description = "Storage account name for Terraform state"
  type        = string
}

variable "state_resource_group" {
  description = "Resource group containing state storage"
  type        = string
  default     = "rg-terraform-state"
}

variable "state_container_name" {
  description = "Container name for state files"
  type        = string
  default     = "tfstate"
}

variable "management_state_key" {
  description = "State file key for management deployment"
  type        = string
  default     = "management.tfstate"
}
variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID from Management deployment"
  type        = string
}