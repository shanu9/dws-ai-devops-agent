# =============================================================================
# AZURE FUNCTIONS MODULE VARIABLES
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

variable "function_app_name" {
  description = "Function app name (auto-generated if not provided)"
  type        = string
  default     = null
}

variable "os_type" {
  description = "OS type (Linux or Windows)"
  type        = string
  default     = "Linux"
  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "Must be Linux or Windows."
  }
}

variable "plan_type" {
  description = "Plan type (Consumption, Premium, or Dedicated)"
  type        = string
  default     = "Consumption"
  validation {
    condition     = contains(["Consumption", "ElasticPremium", "Dedicated"], var.plan_type)
    error_message = "Must be Consumption, ElasticPremium, or Dedicated."
  }
}

variable "plan_sku" {
  description = "App Service Plan SKU (if not Consumption)"
  type        = string
  default     = "EP1" # Elastic Premium
}

variable "max_elastic_workers" {
  description = "Maximum elastic workers (Elastic Premium only)"
  type        = number
  default     = 20
}

variable "runtime" {
  description = "Runtime stack (node, python, dotnet, java, powershell)"
  type        = string
  default     = "node"
  validation {
    condition     = contains(["node", "python", "dotnet", "java", "powershell"], var.runtime)
    error_message = "Must be node, python, dotnet, java, or powershell."
  }
}

variable "runtime_version" {
  description = "Runtime version"
  type        = string
  default     = "18" # Node.js 18
}

variable "always_on" {
  description = "Keep app always loaded (not available on Consumption)"
  type        = bool
  default     = false
}

variable "app_settings" {
  description = "Application settings"
  type        = map(string)
  default     = {}
}

variable "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  type        = string
  default     = null
  sensitive   = true
}

variable "app_insights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  default     = null
  sensitive   = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "vnet_integration_subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Create private endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID"
  type        = string
  default     = null
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = []
}

variable "cors_support_credentials" {
  description = "CORS support credentials"
  type        = bool
  default     = false
}

variable "ip_restrictions" {
  description = "IP restrictions"
  type = list(object({
    name       = string
    ip_address = string
    priority   = number
    action     = string
  }))
  default = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "cost_center" {
  description = "Cost center"
  type        = string
  default     = "Serverless-Compute"
}

variable "team" {
  description = "Team"
  type        = string
  default     = "Platform"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}