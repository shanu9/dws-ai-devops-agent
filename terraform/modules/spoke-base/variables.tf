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
  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "Environment must be dev, stg, or prd."
  }
}

variable "spoke_name" {
  description = "Spoke name/identifier (e.g., production, development, analytics)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.spoke_name))
    error_message = "Spoke name must be 3-20 lowercase alphanumeric characters or hyphens."
  }
}

variable "region" {
  description = "Azure region for spoke deployment"
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
# HUB CONNECTIVITY (Required from Hub Module)
# =============================================================================
variable "enable_vpn_gateway" {
  description = "Whether Hub has VPN Gateway enabled"
  type        = bool
  default     = false
}
variable "hub_vnet_id" {
  description = "Hub VNet ID for peering (from Hub module output)"
  type        = string
}

variable "hub_vnet_name" {
  description = "Hub VNet name"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Hub Resource Group name"
  type        = string
}

variable "hub_firewall_private_ip" {
  description = "Hub Firewall private IP (used as next hop in route tables)"
  type        = string
}

variable "hub_location" {
  description = "Hub location (for peering validation)"
  type        = string
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

variable "spoke_vnet_address_space" {
  description = "Address space for Spoke VNet (CIDR notation)"
  type        = list(string)
  validation {
    condition     = length(var.spoke_vnet_address_space) > 0 && can(cidrhost(var.spoke_vnet_address_space[0], 0))
    error_message = "Must provide at least one valid CIDR block."
  }
}

# Subnet Configuration (from your architecture diagram)
variable "database_subnet_prefix" {
  description = "Address prefix for database subnet (SQL, Synapse, Cosmos, etc.)"
  type        = string
  default     = null # Auto-calculated if not provided
}

variable "private_subnet_prefix" {
  description = "Address prefix for private subnet (private endpoints, internal services)"
  type        = string
  default     = null # Auto-calculated if not provided
}

variable "application_subnet_prefix" {
  description = "Address prefix for application subnet (VMs, AKS, App Services)"
  type        = string
  default     = null # Auto-calculated if not provided
}

# Optional subnets
variable "enable_aks_subnet" {
  description = "Create dedicated subnet for AKS cluster"
  type        = bool
  default     = false
}

variable "aks_subnet_prefix" {
  description = "Address prefix for AKS subnet (requires /20 or larger)"
  type        = string
  default     = null
}

variable "enable_additional_subnets" {
  description = "Create additional custom subnets"
  type        = bool
  default     = false
}

variable "additional_subnets" {
  description = "Map of additional subnets to create"
  type = map(object({
    address_prefix = string
    service_endpoints = list(string)
    delegation = object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })
  }))
  default = {}
}

# =============================================================================
# SERVICE ENDPOINTS (For Azure Services)
# =============================================================================

variable "database_subnet_service_endpoints" {
  description = "Service endpoints for database subnet"
  type        = list(string)
  default = [
    "Microsoft.Sql",
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.AzureCosmosDB"
  ]
}

variable "private_subnet_service_endpoints" {
  description = "Service endpoints for private subnet"
  type        = list(string)
  default = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.EventHub",
    "Microsoft.ServiceBus",
    "Microsoft.CognitiveServices"
  ]
}

variable "application_subnet_service_endpoints" {
  description = "Service endpoints for application subnet"
  type        = list(string)
  default = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Web"
  ]
}

# =============================================================================
# NETWORK SECURITY GROUPS (NSGs)
# =============================================================================

variable "enable_default_nsg_rules" {
  description = "Apply default security rules to NSGs"
  type        = bool
  default     = true
}

variable "allowed_inbound_ip_ranges" {
  description = "IP ranges allowed for inbound management traffic (RDP/SSH)"
  type        = list(string)
  default     = [] # Empty = deny all inbound by default (use Bastion)
}

variable "custom_nsg_rules" {
  description = "Custom NSG rules to apply (in addition to defaults)"
  type = map(object({
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = {}
}

# =============================================================================
# PRIVATE DNS INTEGRATION
# =============================================================================

variable "private_dns_zone_ids" {
  description = "Map of Private DNS zone IDs from Hub (for private endpoint DNS)"
  type        = map(string)
  default     = {}
}

variable "enable_private_dns_integration" {
  description = "Link Spoke VNet to Hub's Private DNS zones"
  type        = bool
  default     = true
}

# =============================================================================
# VNET PEERING CONFIGURATION
# =============================================================================

variable "allow_gateway_transit" {
  description = "Allow Hub to use Spoke's gateway (if Spoke has VPN/ER)"
  type        = bool
  default     = false
}

variable "use_remote_gateways" {
  description = "Use Hub's VPN Gateway for on-premises connectivity"
  type        = bool
  default     = true
}

variable "allow_forwarded_traffic" {
  description = "Allow traffic forwarded from other VNets (required for Hub-Spoke)"
  type        = bool
  default     = true
}

# =============================================================================
# ROUTE TABLES (Force traffic through Firewall)
# =============================================================================

variable "enable_forced_tunneling" {
  description = "Force all internet traffic through Hub Firewall"
  type        = bool
  default     = true
}

variable "route_table_disable_bgp_propagation" {
  description = "Disable BGP route propagation (prevent on-prem routes)"
  type        = bool
  default     = true
}

variable "custom_routes" {
  description = "Additional custom routes beyond default (0.0.0.0/0 via Firewall)"
  type = map(object({
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = string
  }))
  default = {}
}

# =============================================================================
# MONITORING & DIAGNOSTICS
# =============================================================================

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID (from Management module)"
  type        = string
}

variable "enable_network_watcher" {
  description = "Enable Network Watcher flow logs for NSGs"
  type        = bool
  default     = true
}

variable "nsg_flow_log_retention_days" {
  description = "NSG flow log retention period (days)"
  type        = number
  default     = 90
}

variable "diagnostic_log_retention_days" {
  description = "Diagnostic log retention period (days)"
  type        = number
  default     = 90
}

# =============================================================================
# TAGGING STRATEGY (Cost Allocation)
# =============================================================================

variable "tags" {
  description = "Common tags to apply to all spoke resources"
  type        = map(string)
  default     = {}
}

variable "mandatory_tags" {
  description = "Mandatory tags that cannot be overridden"
  type        = map(string)
  default     = {}
}

variable "cost_center" {
  description = "Cost center for this spoke (for cost allocation)"
  type        = string
}

variable "team" {
  description = "Team owning this spoke"
  type        = string
}

variable "chargeback_enabled" {
  description = "Enable chargeback for this spoke's costs"
  type        = bool
  default     = true
}

# =============================================================================
# DDoS PROTECTION
# =============================================================================

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Standard (uses Hub's DDoS plan if available)"
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "DDoS Protection Plan ID (from Hub module, if enabled)"
  type        = string
  default     = null
}

# =============================================================================
# SECURITY & COMPLIANCE
# =============================================================================

variable "enable_private_endpoint_network_policies" {
  description = "Enable network policies on private endpoint subnets"
  type        = bool
  default     = false # Typically disabled for private endpoints
}

variable "enable_service_endpoint_network_policies" {
  description = "Enable network policies on service endpoint subnets"
  type        = bool
  default     = false
}

# =============================================================================
# AZURE POLICY EXEMPTIONS
# =============================================================================

variable "policy_exemptions" {
  description = "Policy exemptions for this spoke (if needed)"
  type = map(object({
    policy_assignment_id = string
    exemption_category   = string
    expires_on           = string
  }))
  default = {}
}

# =============================================================================
# DEPLOYMENT OPTIONS
# =============================================================================

variable "create_resource_group" {
  description = "Create new resource group for spoke (vs using existing)"
  type        = bool
  default     = true
}

variable "existing_resource_group_name" {
  description = "Existing resource group name (if create_resource_group = false)"
  type        = string
  default     = null
}

variable "deployment_mode" {
  description = "Deployment mode: standard, minimal, or advanced"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "minimal", "advanced"], var.deployment_mode)
    error_message = "Must be: standard, minimal, or advanced."
  }
}