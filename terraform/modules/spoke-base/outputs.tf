# =============================================================================
# SPOKE-BASE MODULE OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# RESOURCE GROUP
# -----------------------------------------------------------------------------

output "resource_group_id" {
  description = "Spoke Resource Group ID"
  value       = var.create_resource_group ? azurerm_resource_group.spoke[0].id : data.azurerm_resource_group.existing[0].id
}

output "resource_group_name" {
  description = "Spoke Resource Group name"
  value       = local.resource_group_name_final
}

output "resource_group_location" {
  description = "Spoke Resource Group location"
  value       = local.resource_group_location
}

# -----------------------------------------------------------------------------
# VIRTUAL NETWORK
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "Spoke VNet ID"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Spoke VNet name"
  value       = azurerm_virtual_network.spoke.name
}

output "vnet_address_space" {
  description = "Spoke VNet address space"
  value       = azurerm_virtual_network.spoke.address_space
}

# -----------------------------------------------------------------------------
# SUBNETS (Critical for service modules)
# -----------------------------------------------------------------------------

output "database_subnet_id" {
  description = "Database subnet ID (for SQL, Synapse, Cosmos, etc.)"
  value       = azurerm_subnet.database.id
}

output "private_subnet_id" {
  description = "Private subnet ID (for private endpoints)"
  value       = azurerm_subnet.private.id
}

output "application_subnet_id" {
  description = "Application subnet ID (for VMs, App Services, Functions)"
  value       = azurerm_subnet.application.id
}

output "aks_subnet_id" {
  description = "AKS subnet ID (if enabled)"
  value       = var.enable_aks_subnet ? azurerm_subnet.aks[0].id : null
}

output "subnet_ids" {
  description = "Map of all subnet IDs"
  value = {
    database    = azurerm_subnet.database.id
    private     = azurerm_subnet.private.id
    application = azurerm_subnet.application.id
    aks         = var.enable_aks_subnet ? azurerm_subnet.aks[0].id : null
  }
}

# -----------------------------------------------------------------------------
# NETWORK SECURITY GROUPS
# -----------------------------------------------------------------------------

output "nsg_ids" {
  description = "Map of NSG IDs by subnet"
  value = {
    database    = azurerm_network_security_group.database.id
    private     = azurerm_network_security_group.private.id
    application = azurerm_network_security_group.application.id
    aks         = var.enable_aks_subnet ? azurerm_network_security_group.aks[0].id : null
  }
}

# -----------------------------------------------------------------------------
# ROUTE TABLES
# -----------------------------------------------------------------------------

output "route_table_ids" {
  description = "Map of Route Table IDs"
  value = {
    database    = azurerm_route_table.database.id
    private     = azurerm_route_table.private.id
    application = azurerm_route_table.application.id
    aks         = var.enable_aks_subnet ? azurerm_route_table.aks[0].id : null
  }
}

# -----------------------------------------------------------------------------
# VNET PEERING
# -----------------------------------------------------------------------------

output "spoke_to_hub_peering_id" {
  description = "Spoke-to-Hub peering ID"
  value       = azurerm_virtual_network_peering.spoke_to_hub.id
}

output "hub_to_spoke_peering_id" {
  description = "Hub-to-Spoke peering ID"
  value       = azurerm_virtual_network_peering.hub_to_spoke.id
}

# -----------------------------------------------------------------------------
# SPOKE CONFIGURATION (For service modules)
# -----------------------------------------------------------------------------

output "spoke_config" {
  description = "Complete spoke configuration for service module consumption"
  value = {
    vnet_id             = azurerm_virtual_network.spoke.id
    vnet_name           = azurerm_virtual_network.spoke.name
    resource_group_name = local.resource_group_name_final
    location            = local.resource_group_location
    
    subnets = {
      database_id    = azurerm_subnet.database.id
      private_id     = azurerm_subnet.private.id
      application_id = azurerm_subnet.application.id
      aks_id         = var.enable_aks_subnet ? azurerm_subnet.aks[0].id : null
    }
    
    hub_firewall_ip = var.hub_firewall_private_ip
    dns_servers     = [var.hub_firewall_private_ip]
  }
}

# -----------------------------------------------------------------------------
# COST TRACKING
# -----------------------------------------------------------------------------

output "cost_tracking" {
  description = "Cost tracking metadata"
  value = {
    customer_id       = var.customer_id
    environment       = var.environment
    spoke_name        = var.spoke_name
    cost_center       = var.cost_center
    team              = var.team
    chargeback_enabled = var.chargeback_enabled
    resource_group_id  = var.create_resource_group ? azurerm_resource_group.spoke[0].id : data.azurerm_resource_group.existing[0].id
    vnet_id           = azurerm_virtual_network.spoke.id
  }
}

# -----------------------------------------------------------------------------
# DEPLOYMENT SUMMARY
# -----------------------------------------------------------------------------

output "deployment_summary" {
  description = "Human-readable deployment summary"
  value = <<-EOT
    ============================================================
    Spoke Deployment: ${var.spoke_name}
    ============================================================
    Customer:     ${var.customer_id}
    Environment:  ${var.environment}
    Region:       ${var.region}
    
    VNet:         ${azurerm_virtual_network.spoke.name}
    Address:      ${join(", ", azurerm_virtual_network.spoke.address_space)}
    
    Subnets:
      - Database:    ${local.database_subnet_cidr}
      - Private:     ${local.private_subnet_cidr}
      - Application: ${local.application_subnet_cidr}
      ${var.enable_aks_subnet ? "- AKS:         ${local.aks_subnet_cidr}" : ""}
    
    Hub Peering:  Enabled
    Firewall:     ${var.hub_firewall_private_ip} (next hop)
    
    Cost Center:  ${var.cost_center}
    Team:         ${var.team}
    ============================================================
  EOT
}