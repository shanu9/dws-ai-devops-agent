# =============================================================================
# GLOBAL VARIABLES - Naming & Identification
# =============================================================================

variable "customer_id" {
  description = "Unique customer identifier (3-6 characters, lowercase alphanumeric)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,6}$", var.customer_id))
    error_message = "Customer ID must be 3-6 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment name (dev/stg/prd)"
  type        = string
  default     = "prd"
  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "Environment must be dev, stg, or prd."
  }
}

variable "region" {
  description = "Azure region for resource deployment"
  type        = string
}

variable "region_code" {
  description = "Short region code (e.g., eus, wus, jpe, jpw)"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2,4}$", var.region_code))
    error_message = "Region code must be 2-4 lowercase letters."
  }
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

variable "hub_vnet_address_space" {
  description = "Address space for Hub VNet (CIDR notation)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
  validation {
    condition     = can(cidrhost(var.hub_vnet_address_space[0], 0))
    error_message = "Hub VNet address space must be valid CIDR notation."
  }
}

variable "firewall_subnet_prefix" {
  description = "Address prefix for Azure Firewall subnet (minimum /26)"
  type        = string
  default     = null # Auto-calculated from VNet if not specified
}

variable "bastion_subnet_prefix" {
  description = "Address prefix for Azure Bastion subnet (minimum /26)"
  type        = string
  default     = null # Auto-calculated from VNet if not specified
}

variable "gateway_subnet_prefix" {
  description = "Address prefix for VPN Gateway subnet (minimum /27)"
  type        = string
  default     = null # Auto-calculated from VNet if not specified
}

# =============================================================================
# FIREWALL CONFIGURATION
# =============================================================================

variable "firewall_sku_tier" {
  description = "Azure Firewall SKU tier (Standard/Premium). Premium adds TLS inspection, IDPS."
  type        = string
  default     = "Standard" # Cost optimization: Standard for most use cases
  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "Firewall SKU must be Standard or Premium."
  }
}

variable "firewall_threat_intel_mode" {
  description = "Threat intelligence mode (Off/Alert/Deny)"
  type        = string
  default     = "Alert" # Best practice: Alert in production
  validation {
    condition     = contains(["Off", "Alert", "Deny"], var.firewall_threat_intel_mode)
    error_message = "Valid values: Off, Alert, Deny."
  }
}

variable "enable_firewall_dns_proxy" {
  description = "Enable DNS proxy on Azure Firewall (required for FQDN filtering)"
  type        = bool
  default     = true
}

variable "firewall_dns_servers" {
  description = "Custom DNS servers for Firewall. Leave empty for Azure DNS."
  type        = list(string)
  default     = []
}

variable "firewall_availability_zones" {
  description = "Availability zones for Firewall (high availability). Empty = no zones."
  type        = list(string)
  default     = ["1", "2", "3"] # Best practice: Use zones for 99.99% SLA
}

# =============================================================================
# BASTION CONFIGURATION
# =============================================================================

variable "enable_bastion" {
  description = "Deploy Azure Bastion for secure VM access"
  type        = bool
  default     = true
}

variable "bastion_sku" {
  description = "Azure Bastion SKU (Basic/Standard). Standard adds features like native client, file transfer."
  type        = string
  default     = "Basic" # Cost optimization: Basic for standard use cases
  validation {
    condition     = contains(["Basic", "Standard"], var.bastion_sku)
    error_message = "Bastion SKU must be Basic or Standard."
  }
}

variable "bastion_scale_units" {
  description = "Number of scale units for Bastion (2-50). Only for Standard SKU."
  type        = number
  default     = 2
  validation {
    condition     = var.bastion_scale_units >= 2 && var.bastion_scale_units <= 50
    error_message = "Scale units must be between 2 and 50."
  }
}

# =============================================================================
# VPN GATEWAY CONFIGURATION
# =============================================================================

variable "enable_vpn_gateway" {
  description = "Deploy VPN Gateway for on-premises connectivity"
  type        = bool
  default     = false # Cost optimization: Only deploy when needed
}

variable "vpn_gateway_sku" {
  description = "VPN Gateway SKU (VpnGw1/VpnGw2/VpnGw3/VpnGw1AZ/VpnGw2AZ/VpnGw3AZ)"
  type        = string
  default     = "VpnGw1" # Cost optimization: Basic VPN for small deployments
  validation {
    condition     = contains(["VpnGw1", "VpnGw2", "VpnGw3", "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ"], var.vpn_gateway_sku)
    error_message = "Must be a valid VPN Gateway SKU."
  }
}

variable "vpn_gateway_type" {
  description = "VPN Gateway type (Vpn/RouteBased)"
  type        = string
  default     = "Vpn"
}

variable "vpn_gateway_generation" {
  description = "VPN Gateway generation (Generation1/Generation2)"
  type        = string
  default     = "Generation2" # Best practice: Gen2 for better performance
}

# =============================================================================
# PRIVATE DNS CONFIGURATION
# =============================================================================

variable "enable_private_dns_zones" {
  description = "Create Private DNS zones for Azure services"
  type        = bool
  default     = true
}

variable "private_dns_zones" {
  description = "List of Private DNS zones to create for Azure services"
  type        = list(string)
  default = [
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.queue.core.windows.net",
    "privatelink.table.core.windows.net",
    "privatelink.database.windows.net",
    "privatelink.sql.azuresynapse.net",
    "privatelink.documents.azure.com",
    "privatelink.mongo.cosmos.azure.com",
    "privatelink.cassandra.cosmos.azure.com",
    "privatelink.gremlin.cosmos.azure.com",
    "privatelink.table.cosmos.azure.com",
    "privatelink.vaultcore.azure.net",
    "privatelink.azurewebsites.net",
    "privatelink.azurecr.io",
    "privatelink.search.windows.net",
    "privatelink.azuresynapse.net",
    "privatelink.servicebus.windows.net",
    "privatelink.eventgrid.azure.net",
    "privatelink.cognitiveservices.azure.com",
    "privatelink.openai.azure.com",
    "privatelink.redis.cache.windows.net"
  ]
}

# =============================================================================
# MONITORING & DIAGNOSTICS
# =============================================================================

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostics (from Management module)"
  type        = string
}

variable "enable_network_watcher" {
  description = "Deploy Network Watcher for network monitoring"
  type        = bool
  default     = true
}

variable "diagnostic_log_retention_days" {
  description = "Number of days to retain diagnostic logs (0 = infinite, max 365)"
  type        = number
  default     = 90 # Cost optimization: 90 days standard retention
  validation {
    condition     = var.diagnostic_log_retention_days >= 0 && var.diagnostic_log_retention_days <= 365
    error_message = "Retention must be between 0 and 365 days."
  }
}

# =============================================================================
# TAGGING STRATEGY
# =============================================================================

variable "tags" {
  description = "Common tags to apply to all resources (merged with default tags)"
  type        = map(string)
  default     = {}
}

variable "mandatory_tags" {
  description = "Mandatory tags that cannot be overridden"
  type        = map(string)
  default     = {}
}

# =============================================================================
# COST OPTIMIZATION
# =============================================================================

variable "enable_cost_alerts" {
  description = "Enable cost monitoring and alerts for Hub resources"
  type        = bool
  default     = true
}

variable "monthly_budget_amount" {
  description = "Monthly budget limit for Hub subscription (USD). 0 = no budget."
  type        = number
  default     = 0
}

# =============================================================================
# SECURITY & COMPLIANCE
# =============================================================================

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Standard (significant cost, ~$3000/month)"
  type        = bool
  default     = false # Cost optimization: Only for critical production
}

variable "allowed_management_ips" {
  description = "List of IP addresses/ranges allowed to access management resources"
  type        = list(string)
  default     = []
}

# =============================================================================
# HIGH AVAILABILITY
# =============================================================================

variable "enable_zone_redundancy" {
  description = "Enable zone redundancy for all supported resources (higher cost, better SLA)"
  type        = bool
  default     = true # Best practice: Enabled by default
}