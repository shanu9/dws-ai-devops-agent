# =============================================================================
# HUB MODULE OUTPUTS
# =============================================================================
# Purpose: Export Hub resource information for use by Spoke and Management modules
# Usage: Other modules reference these outputs for connectivity and routing
# Best Practice: Comprehensive outputs for full integration capability
# =============================================================================

# -----------------------------------------------------------------------------
# RESOURCE GROUP OUTPUTS
# -----------------------------------------------------------------------------

output "resource_group_id" {
  description = "Hub Resource Group ID"
  value       = azurerm_resource_group.hub.id
}

output "resource_group_name" {
  description = "Hub Resource Group name"
  value       = azurerm_resource_group.hub.name
}

output "resource_group_location" {
  description = "Hub Resource Group location"
  value       = azurerm_resource_group.hub.location
}

# -----------------------------------------------------------------------------
# VIRTUAL NETWORK OUTPUTS
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "Hub Virtual Network ID (required for VNet peering)"
  value       = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  description = "Hub Virtual Network name"
  value       = azurerm_virtual_network.hub.name
}

output "vnet_address_space" {
  description = "Hub VNet address space (CIDR blocks)"
  value       = azurerm_virtual_network.hub.address_space
}

output "vnet_resource_group_name" {
  description = "Resource group containing Hub VNet"
  value       = azurerm_virtual_network.hub.resource_group_name
}

output "vnet_guid" {
  description = "Hub VNet GUID (unique identifier)"
  value       = azurerm_virtual_network.hub.guid
}

output "vnet_subnets" {
  description = "Hub VNet subnet information"
  value = {
    firewall_subnet_id = azurerm_subnet.firewall.id
    bastion_subnet_id  = var.enable_bastion ? azurerm_subnet.bastion[0].id : null
    gateway_subnet_id  = var.enable_vpn_gateway ? azurerm_subnet.gateway[0].id : null
  }
}

# -----------------------------------------------------------------------------
# AZURE FIREWALL OUTPUTS (CRITICAL FOR ROUTING)
# -----------------------------------------------------------------------------

output "firewall_id" {
  description = "Azure Firewall resource ID"
  value       = azurerm_firewall.hub.id
}

output "firewall_name" {
  description = "Azure Firewall name"
  value       = azurerm_firewall.hub.name
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP address (CRITICAL: Used as next hop in route tables)"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Azure Firewall public IP address (for outbound traffic)"
  value       = azurerm_public_ip.firewall.ip_address
}

output "firewall_policy_id" {
  description = "Azure Firewall Policy ID (for policy modifications)"
  value       = azurerm_firewall_policy.hub.id
}

output "firewall_policy_name" {
  description = "Azure Firewall Policy name"
  value       = azurerm_firewall_policy.hub.name
}

output "firewall_sku_tier" {
  description = "Azure Firewall SKU tier (Standard/Premium)"
  value       = azurerm_firewall.hub.sku_tier
}

output "firewall_availability_zones" {
  description = "Azure Firewall availability zones"
  value       = azurerm_firewall.hub.zones
}

# Firewall DNS Proxy (for spoke DNS configuration)
output "firewall_dns_proxy_enabled" {
  description = "Whether Firewall DNS proxy is enabled (affects spoke DNS settings)"
  value       = var.enable_firewall_dns_proxy
}

# -----------------------------------------------------------------------------
# AZURE BASTION OUTPUTS
# -----------------------------------------------------------------------------

output "bastion_id" {
  description = "Azure Bastion resource ID"
  value       = var.enable_bastion ? azurerm_bastion_host.hub[0].id : null
}

output "bastion_name" {
  description = "Azure Bastion name"
  value       = var.enable_bastion ? azurerm_bastion_host.hub[0].name : null
}

output "bastion_fqdn" {
  description = "Azure Bastion FQDN (for secure VM access)"
  value       = var.enable_bastion ? azurerm_bastion_host.hub[0].dns_name : null
}

output "bastion_enabled" {
  description = "Whether Bastion is deployed"
  value       = var.enable_bastion
}

output "bastion_sku" {
  description = "Azure Bastion SKU (Basic/Standard)"
  value       = var.enable_bastion ? var.bastion_sku : null
}

# -----------------------------------------------------------------------------
# VPN GATEWAY OUTPUTS
# -----------------------------------------------------------------------------

output "vpn_gateway_id" {
  description = "VPN Gateway resource ID"
  value       = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].id : null
}

output "vpn_gateway_name" {
  description = "VPN Gateway name"
  value       = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].name : null
}

output "vpn_gateway_public_ip" {
  description = "VPN Gateway public IP address (for on-premises configuration)"
  value       = var.enable_vpn_gateway ? azurerm_public_ip.vpn[0].ip_address : null
}

output "vpn_gateway_sku" {
  description = "VPN Gateway SKU"
  value       = var.enable_vpn_gateway ? var.vpn_gateway_sku : null
}

output "vpn_gateway_enabled" {
  description = "Whether VPN Gateway is deployed"
  value       = var.enable_vpn_gateway
}

output "vpn_gateway_bgp_settings" {
  description = "VPN Gateway BGP settings (for on-premises router configuration)"
  value = var.enable_vpn_gateway ? {
    asn         = azurerm_virtual_network_gateway.vpn[0].bgp_settings[0].asn
    peering_address = azurerm_virtual_network_gateway.vpn[0].bgp_settings[0].peering_addresses[0].default_addresses[0]
  } : null
}

# -----------------------------------------------------------------------------
# PRIVATE DNS ZONES OUTPUTS
# -----------------------------------------------------------------------------

output "private_dns_zones" {
  description = "Map of Private DNS zone names to their IDs"
  value = var.enable_private_dns_zones ? {
    for zone_name, zone in azurerm_private_dns_zone.hub : zone_name => zone.id
  } : {}
}

output "private_dns_zone_names" {
  description = "List of Private DNS zone names"
  value       = var.enable_private_dns_zones ? keys(azurerm_private_dns_zone.hub) : []
}

output "private_dns_zones_enabled" {
  description = "Whether Private DNS zones are created"
  value       = var.enable_private_dns_zones
}

# Private DNS zone details for specific services (commonly needed)
output "private_dns_zone_ids" {
  description = "Private DNS zone IDs for specific Azure services"
  value = var.enable_private_dns_zones ? {
    blob_storage           = try(azurerm_private_dns_zone.hub["privatelink.blob.core.windows.net"].id, null)
    file_storage           = try(azurerm_private_dns_zone.hub["privatelink.file.core.windows.net"].id, null)
    sql_database           = try(azurerm_private_dns_zone.hub["privatelink.database.windows.net"].id, null)
    synapse                = try(azurerm_private_dns_zone.hub["privatelink.sql.azuresynapse.net"].id, null)
    cosmos_db              = try(azurerm_private_dns_zone.hub["privatelink.documents.azure.com"].id, null)
    key_vault              = try(azurerm_private_dns_zone.hub["privatelink.vaultcore.azure.net"].id, null)
    web_apps               = try(azurerm_private_dns_zone.hub["privatelink.azurewebsites.net"].id, null)
    container_registry     = try(azurerm_private_dns_zone.hub["privatelink.azurecr.io"].id, null)
    cognitive_services     = try(azurerm_private_dns_zone.hub["privatelink.cognitiveservices.azure.com"].id, null)
    openai                 = try(azurerm_private_dns_zone.hub["privatelink.openai.azure.com"].id, null)
    event_hub              = try(azurerm_private_dns_zone.hub["privatelink.servicebus.windows.net"].id, null)
    cognitive_search       = try(azurerm_private_dns_zone.hub["privatelink.search.windows.net"].id, null)
  } : {}
}

# -----------------------------------------------------------------------------
# NETWORK WATCHER OUTPUTS
# -----------------------------------------------------------------------------

output "network_watcher_id" {
  description = "Network Watcher resource ID"
  value       = var.enable_network_watcher ? azurerm_network_watcher.hub[0].id : null
}

output "network_watcher_name" {
  description = "Network Watcher name"
  value       = var.enable_network_watcher ? azurerm_network_watcher.hub[0].name : null
}

output "network_watcher_enabled" {
  description = "Whether Network Watcher is deployed"
  value       = var.enable_network_watcher
}

# -----------------------------------------------------------------------------
# DDOS PROTECTION OUTPUTS
# -----------------------------------------------------------------------------

output "ddos_protection_plan_id" {
  description = "DDoS Protection Plan ID (if enabled)"
  value       = var.enable_ddos_protection ? azurerm_network_ddos_protection_plan.hub[0].id : null
}

output "ddos_protection_enabled" {
  description = "Whether DDoS Protection is enabled"
  value       = var.enable_ddos_protection
}

# -----------------------------------------------------------------------------
# CONFIGURATION OUTPUTS (FOR SPOKE MODULES)
# -----------------------------------------------------------------------------

output "hub_config" {
  description = "Hub configuration summary for Spoke module consumption"
  value = {
    # Network configuration
    vnet_id              = azurerm_virtual_network.hub.id
    vnet_name            = azurerm_virtual_network.hub.name
    vnet_address_space   = azurerm_virtual_network.hub.address_space
    resource_group_name  = azurerm_resource_group.hub.name
    location             = azurerm_resource_group.hub.location
    
    # Firewall configuration (CRITICAL for route tables)
    firewall_private_ip  = azurerm_firewall.hub.ip_configuration[0].private_ip_address
    firewall_id          = azurerm_firewall.hub.id
    dns_proxy_enabled    = var.enable_firewall_dns_proxy
    
    # DNS configuration
    dns_servers = var.enable_firewall_dns_proxy ? [
      azurerm_firewall.hub.ip_configuration[0].private_ip_address
    ] : []
    
    # Bastion configuration
    bastion_enabled = var.enable_bastion
    bastion_id      = var.enable_bastion ? azurerm_bastion_host.hub[0].id : null
    
    # VPN configuration
    vpn_enabled = var.enable_vpn_gateway
    
    # Private DNS
    private_dns_zones = var.enable_private_dns_zones ? keys(azurerm_private_dns_zone.hub) : []
  }
}

# -----------------------------------------------------------------------------
# COST TRACKING OUTPUTS (FOR COST INTELLIGENCE)
# -----------------------------------------------------------------------------

output "cost_tracking" {
  description = "Cost tracking information for cost intelligence engine"
  value = {
    # Resource identification
    customer_id   = var.customer_id
    environment   = var.environment
    component     = "Hub"
    region        = var.region
    
    # High-cost resources flagged
    firewall_sku              = var.firewall_sku_tier
    firewall_zones_enabled    = var.enable_zone_redundancy
    bastion_enabled           = var.enable_bastion
    bastion_sku               = var.enable_bastion ? var.bastion_sku : null
    vpn_enabled               = var.enable_vpn_gateway
    vpn_sku                   = var.enable_vpn_gateway ? var.vpn_gateway_sku : null
    ddos_protection_enabled   = var.enable_ddos_protection
    
    # Resource tags for cost allocation
    cost_center = "Platform-${var.customer_id}"
    tags        = local.common_tags
    
    # Resource IDs for cost queries
    resource_group_id = azurerm_resource_group.hub.id
    firewall_id       = azurerm_firewall.hub.id
    bastion_id        = var.enable_bastion ? azurerm_bastion_host.hub[0].id : null
    vpn_gateway_id    = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].id : null
  }
}

# -----------------------------------------------------------------------------
# SECURITY OUTPUTS (FOR COMPLIANCE REPORTING)
# -----------------------------------------------------------------------------

output "security_config" {
  description = "Security configuration summary for compliance reporting"
  value = {
    # Firewall security
    firewall_threat_intel_mode = var.firewall_threat_intel_mode
    firewall_dns_proxy_enabled = var.enable_firewall_dns_proxy
    firewall_sku_tier          = var.firewall_sku_tier
    
    # Network security
    ddos_protection_enabled = var.enable_ddos_protection
    network_watcher_enabled = var.enable_network_watcher
    
    # Access control
    bastion_enabled            = var.enable_bastion
    allowed_management_ips     = var.allowed_management_ips
    
    # High availability
    zone_redundancy_enabled = var.enable_zone_redundancy
    firewall_zones          = azurerm_firewall.hub.zones
    
    # Monitoring
    log_analytics_workspace_id = var.log_analytics_workspace_id
    diagnostic_retention_days  = var.diagnostic_log_retention_days
  }
}

# -----------------------------------------------------------------------------
# OPERATIONAL OUTPUTS (FOR RUNBOOKS & AUTOMATION)
# -----------------------------------------------------------------------------

output "operational_info" {
  description = "Operational information for runbooks and automation"
  value = {
    # Naming convention
    naming_prefix     = local.naming_prefix
    customer_id       = var.customer_id
    environment       = var.environment
    region_code       = var.region_code
    
    # Resource names (for scripts)
    resource_group_name  = azurerm_resource_group.hub.name
    vnet_name            = azurerm_virtual_network.hub.name
    firewall_name        = azurerm_firewall.hub.name
    firewall_policy_name = azurerm_firewall_policy.hub.name
    bastion_name         = var.enable_bastion ? azurerm_bastion_host.hub[0].name : null
    vpn_gateway_name     = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].name : null
    
    # Deployment metadata
    deployment_date = formatdate("YYYY-MM-DD", timestamp())
    terraform_managed = true
  }
  
  
}

# -----------------------------------------------------------------------------
# INTEGRATION OUTPUTS (FOR SPOKE PEERING)
# -----------------------------------------------------------------------------

output "peering_config" {
  description = "Configuration required for Spoke-to-Hub VNet peering"
  value = {
    hub_vnet_id                  = azurerm_virtual_network.hub.id
    hub_vnet_name                = azurerm_virtual_network.hub.name
    hub_resource_group_name      = azurerm_resource_group.hub.name
    allow_gateway_transit        = var.enable_vpn_gateway # Allow if VPN Gateway exists
    use_remote_gateways_allowed  = var.enable_vpn_gateway
    allow_forwarded_traffic      = true # Required for firewall routing
    allow_virtual_network_access = true
  }
}

# -----------------------------------------------------------------------------
# SUMMARY OUTPUT (HUMAN-READABLE)
# -----------------------------------------------------------------------------

output "deployment_summary" {
  description = "Human-readable deployment summary"
  value = <<-EOT
    ============================================================
    Azure CAF-LZ Hub Deployment Summary
    ============================================================
    Customer ID:      ${var.customer_id}
    Environment:      ${var.environment}
    Region:           ${var.region} (${var.region_code})
    
    Hub VNet:         ${azurerm_virtual_network.hub.name}
    Address Space:    ${join(", ", azurerm_virtual_network.hub.address_space)}
    
    Firewall:         ${azurerm_firewall.hub.name}
    Firewall IP:      ${azurerm_firewall.hub.ip_configuration[0].private_ip_address}
    Firewall SKU:     ${var.firewall_sku_tier}
    
    Bastion:          ${var.enable_bastion ? "Enabled (${var.bastion_sku})" : "Disabled"}
    VPN Gateway:      ${var.enable_vpn_gateway ? "Enabled (${var.vpn_gateway_sku})" : "Disabled"}
    
    Private DNS Zones: ${var.enable_private_dns_zones ? length(var.private_dns_zones) : 0} zones
    Zone Redundancy:   ${var.enable_zone_redundancy ? "Enabled" : "Disabled"}
    DDoS Protection:   ${var.enable_ddos_protection ? "Enabled" : "Disabled"}
    
    Cost Center:      Platform-${var.customer_id}
    ============================================================
  EOT
}