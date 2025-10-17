# =============================================================================
# AZURE CAF-LZ SPOKE-BASE MODULE
# =============================================================================
# Purpose: Deploy Spoke VNet infrastructure for workload hosting
# Components: VNet, Subnets, NSGs, Route Tables, VNet Peering, Private DNS
# Best Practices: Forced tunneling via Firewall, cost allocation tags, monitoring
# =============================================================================

# -----------------------------------------------------------------------------
# LOCAL VARIABLES - Naming Convention & Calculated Values
# -----------------------------------------------------------------------------

locals {
  # Naming convention: <resource-type>-<customer-id>-<spoke-name>-<region-code>
  # Example: rg-abc-production-eus, vnet-abc-production-eus
  naming_prefix = "${var.customer_id}-${var.spoke_name}-${var.region_code}"
  
  # Resource names following Azure naming best practices
  resource_group_name = var.create_resource_group ? "rg-${local.naming_prefix}" : var.existing_resource_group_name
  vnet_name           = "vnet-${local.naming_prefix}"
  
  # Route table names (per subnet)
  rt_database_name    = "rt-${local.naming_prefix}-db"
  rt_private_name     = "rt-${local.naming_prefix}-private"
  rt_application_name = "rt-${local.naming_prefix}-app"
  rt_aks_name         = "rt-${local.naming_prefix}-aks"
  
  # NSG names (per subnet)
  nsg_database_name    = "nsg-${local.naming_prefix}-db"
  nsg_private_name     = "nsg-${local.naming_prefix}-private"
  nsg_application_name = "nsg-${local.naming_prefix}-app"
  nsg_aks_name         = "nsg-${local.naming_prefix}-aks"
  
  # Peering names
  spoke_to_hub_peering_name = "peer-${var.spoke_name}-to-hub"
  hub_to_spoke_peering_name = "peer-hub-to-${var.spoke_name}"
  
  # Subnet calculations (if not provided)
  vnet_cidr = var.spoke_vnet_address_space[0]
  
  # Standard subnet layout from your architecture diagram:
  # Database subnet:    10.x.1.0/24 (256 IPs)
  # Private subnet:     10.x.2.0/24 (256 IPs)
  # Application subnet: 10.x.3.0/24 (256 IPs)
  # AKS subnet:         10.x.4.0/22 (1024 IPs - if enabled)
  
  database_subnet_cidr = coalesce(
    var.database_subnet_prefix,
    cidrsubnet(local.vnet_cidr, 8, 1) # /24 subnet
  )
  
  private_subnet_cidr = coalesce(
    var.private_subnet_prefix,
    cidrsubnet(local.vnet_cidr, 8, 2) # /24 subnet
  )
  
  application_subnet_cidr = coalesce(
    var.application_subnet_prefix,
    cidrsubnet(local.vnet_cidr, 8, 3) # /24 subnet
  )
  
  aks_subnet_cidr = var.enable_aks_subnet ? coalesce(
    var.aks_subnet_prefix,
    cidrsubnet(local.vnet_cidr, 6, 1) # /22 subnet (1024 IPs)
  ) : null
  
  # Comprehensive tagging strategy for cost tracking and governance
  common_tags = merge(
    {
      # Mandatory tags for cost allocation
      Customer      = var.customer_id
      Environment   = var.environment
      Spoke         = var.spoke_name
      ManagedBy     = "Terraform"
      Component     = "Spoke"
      CostCenter    = var.cost_center
      Team          = var.team
      
      # Operational tags
      DeploymentDate = formatdate("YYYY-MM-DD", timestamp())
      Region         = var.region
      
      # Cost optimization tags
      ChargebackEnabled = tostring(var.chargeback_enabled)
      
      # Compliance tags
      DataClassification = "Internal"
      Compliance         = "CAF-LZ"
    },
    var.tags,
    var.mandatory_tags
  )
}

# -----------------------------------------------------------------------------
# RESOURCE GROUP
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "spoke" {
  count = var.create_resource_group ? 1 : 0
  
  name     = local.resource_group_name
  location = var.region
  tags     = local.common_tags
  
  lifecycle {
    ignore_changes = [
      tags["DeploymentDate"]
    ]
  }
}

# Data source for existing RG (if not creating new one)
data "azurerm_resource_group" "existing" {
  count = var.create_resource_group ? 0 : 1
  name  = var.existing_resource_group_name
}

locals {
  resource_group_name_final = var.create_resource_group ? azurerm_resource_group.spoke[0].name : data.azurerm_resource_group.existing[0].name
  resource_group_location   = var.create_resource_group ? azurerm_resource_group.spoke[0].location : data.azurerm_resource_group.existing[0].location
}

# -----------------------------------------------------------------------------
# SPOKE VIRTUAL NETWORK
# -----------------------------------------------------------------------------
resource "azurerm_virtual_network" "spoke" {
  name                = local.vnet_name
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name_final
  address_space       = var.spoke_vnet_address_space
  
  # ✅ CRITICAL FIX: Point DNS to Hub Firewall for Private DNS resolution
  dns_servers = [var.hub_firewall_private_ip]
  
  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection && var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }
  
  tags = merge(
    local.common_tags,
    {
      Name    = local.vnet_name
      Purpose = "Spoke VNet for ${var.spoke_name} workloads"
    }
  )
  
  lifecycle {
    prevent_destroy = false # Set to true in production
  }
}
# =============================================================================
# NETWORK SECURITY GROUPS (NSGs) - Per Subnet
# =============================================================================

# -----------------------------------------------------------------------------
# DATABASE SUBNET NSG
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "database" {
  name                = local.nsg_database_name
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name_final
  
  tags = merge(
    local.common_tags,
    {
      Name   = local.nsg_database_name
      Subnet = "Database"
    }
  )
}

# Default NSG Rules for Database Subnet
resource "azurerm_network_security_rule" "database_allow_app_subnet" {
  count = var.enable_default_nsg_rules ? 1 : 0
  
  name                        = "Allow-AppSubnet-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["1433", "3306", "5432", "27017", "10350"] # SQL, MySQL, PostgreSQL, MongoDB, Cosmos
  source_address_prefix       = local.application_subnet_cidr
  destination_address_prefix  = local.database_subnet_cidr
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.database.name
}

resource "azurerm_network_security_rule" "database_deny_internet_inbound" {
  count = var.enable_default_nsg_rules ? 1 : 0
  
  name                        = "Deny-Internet-Inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.database.name
}

resource "azurerm_network_security_rule" "database_deny_internet_outbound" {
  count = var.enable_default_nsg_rules ? 1 : 0
  
  name                        = "Deny-Internet-Outbound"
  priority                    = 4000
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.database.name
}

# -----------------------------------------------------------------------------
# PRIVATE SUBNET NSG (For Private Endpoints)
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "private" {
  name                = local.nsg_private_name
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name_final
  
  tags = merge(
    local.common_tags,
    {
      Name   = local.nsg_private_name
      Subnet = "Private"
    }
  )
}

# Private endpoints typically don't need explicit rules (traffic is private)
resource "azurerm_network_security_rule" "private_allow_vnet" {
  count = var.enable_default_nsg_rules ? 1 : 0
  
  name                        = "Allow-VNet-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.private.name
}

resource "azurerm_network_security_rule" "private_deny_internet" {
  count = var.enable_default_nsg_rules ? 1 : 0
  
  name                        = "Deny-Internet-Inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.private.name
}

# -----------------------------------------------------------------------------
# APPLICATION SUBNET NSG
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "application" {
  name                = local.nsg_application_name
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name_final
  
  tags = merge(
    local.common_tags,
    {
      Name   = local.nsg_application_name
      Subnet = "Application"
    }
  )
}

# Allow HTTP/HTTPS inbound (from Load Balancer/App Gateway)
resource "azurerm_network_security_rule" "app_allow_http" {
  count = var.enable_default_nsg_rules ? 1 : 0
  
  name                        = "Allow-HTTP-HTTPS-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = local.application_subnet_cidr
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.application.name
}

# Allow outbound to database subnet
resource "azurerm_network_security_rule" "app_allow_db_outbound" {
  count = var.enable_default_nsg_rules ? 1 : 0
  
  name                        = "Allow-Database-Outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["1433", "3306", "5432", "27017", "10350"]
  source_address_prefix       = local.application_subnet_cidr
  destination_address_prefix  = local.database_subnet_cidr
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.application.name
}

# Deny direct internet inbound (force through Firewall/App Gateway)
resource "azurerm_network_security_rule" "app_deny_internet_inbound" {
  count = var.enable_default_nsg_rules ? 1 : 0
  
  name                        = "Deny-Internet-Inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.application.name
}

# -----------------------------------------------------------------------------
# AKS SUBNET NSG (if enabled)
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "aks" {
  count = var.enable_aks_subnet ? 1 : 0
  
  name                = local.nsg_aks_name
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name_final
  
  tags = merge(
    local.common_tags,
    {
      Name   = local.nsg_aks_name
      Subnet = "AKS"
    }
  )
}

# AKS-specific rules (allow AKS control plane)
resource "azurerm_network_security_rule" "aks_allow_control_plane" {
  count = var.enable_aks_subnet && var.enable_default_nsg_rules ? 1 : 0
  
  name                        = "Allow-AKS-ControlPlane"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["443", "10250", "9000"]
  source_address_prefix       = "AzureCloud"
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.aks[0].name
}

# =============================================================================
# ROUTE TABLES (Force traffic through Hub Firewall)
# =============================================================================

# -----------------------------------------------------------------------------
# DATABASE SUBNET ROUTE TABLE
# -----------------------------------------------------------------------------

resource "azurerm_route_table" "database" {
  name                          = local.rt_database_name
  location                      = local.resource_group_location
  resource_group_name           = local.resource_group_name_final
  disable_bgp_route_propagation = var.route_table_disable_bgp_propagation
  
  tags = merge(
    local.common_tags,
    {
      Name   = local.rt_database_name
      Subnet = "Database"
    }
  )
}

# Default route: All traffic to Firewall
resource "azurerm_route" "database_default" {
  count = var.enable_forced_tunneling ? 1 : 0
  
  name                   = "default-via-firewall"
  resource_group_name    = local.resource_group_name_final
  route_table_name       = azurerm_route_table.database.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.hub_firewall_private_ip
}

# -----------------------------------------------------------------------------
# PRIVATE SUBNET ROUTE TABLE
# -----------------------------------------------------------------------------

resource "azurerm_route_table" "private" {
  name                          = local.rt_private_name
  location                      = local.resource_group_location
  resource_group_name           = local.resource_group_name_final
  disable_bgp_route_propagation = var.route_table_disable_bgp_propagation
  
  tags = merge(
    local.common_tags,
    {
      Name   = local.rt_private_name
      Subnet = "Private"
    }
  )
}

resource "azurerm_route" "private_default" {
  count = var.enable_forced_tunneling ? 1 : 0
  
  name                   = "default-via-firewall"
  resource_group_name    = local.resource_group_name_final
  route_table_name       = azurerm_route_table.private.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.hub_firewall_private_ip
}

# -----------------------------------------------------------------------------
# APPLICATION SUBNET ROUTE TABLE
# -----------------------------------------------------------------------------

resource "azurerm_route_table" "application" {
  name                          = local.rt_application_name
  location                      = local.resource_group_location
  resource_group_name           = local.resource_group_name_final
  disable_bgp_route_propagation = var.route_table_disable_bgp_propagation
  
  tags = merge(
    local.common_tags,
    {
      Name   = local.rt_application_name
      Subnet = "Application"
    }
  )
}

resource "azurerm_route" "application_default" {
  count = var.enable_forced_tunneling ? 1 : 0
  
  name                   = "default-via-firewall"
  resource_group_name    = local.resource_group_name_final
  route_table_name       = azurerm_route_table.application.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.hub_firewall_private_ip
}

# -----------------------------------------------------------------------------
# AKS SUBNET ROUTE TABLE
# -----------------------------------------------------------------------------

resource "azurerm_route_table" "aks" {
  count = var.enable_aks_subnet ? 1 : 0
  
  name                          = local.rt_aks_name
  location                      = local.resource_group_location
  resource_group_name           = local.resource_group_name_final
  disable_bgp_route_propagation = var.route_table_disable_bgp_propagation
  
  tags = merge(
    local.common_tags,
    {
      Name   = local.rt_aks_name
      Subnet = "AKS"
    }
  )
}

resource "azurerm_route" "aks_default" {
  count = var.enable_aks_subnet && var.enable_forced_tunneling ? 1 : 0
  
  name                   = "default-via-firewall"
  resource_group_name    = local.resource_group_name_final
  route_table_name       = azurerm_route_table.aks[0].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.hub_firewall_private_ip
}

# =============================================================================
# SUBNETS (Database, Private, Application, AKS)
# =============================================================================

# -----------------------------------------------------------------------------
# DATABASE SUBNET (10.x.1.0/24)
# -----------------------------------------------------------------------------

resource "azurerm_subnet" "database" {
  name                 = "snet-${local.naming_prefix}-db"
  resource_group_name  = local.resource_group_name_final
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [local.database_subnet_cidr]
  
  # Service endpoints for Azure PaaS services
  service_endpoints = var.database_subnet_service_endpoints
  
  # Network policies (typically disabled for private endpoints)
  private_endpoint_network_policies_enabled     = var.enable_private_endpoint_network_policies
  private_link_service_network_policies_enabled = var.enable_service_endpoint_network_policies
}

# Associate NSG
resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}

# Associate Route Table
resource "azurerm_subnet_route_table_association" "database" {
  subnet_id      = azurerm_subnet.database.id
  route_table_id = azurerm_route_table.database.id
}

# -----------------------------------------------------------------------------
# PRIVATE SUBNET (10.x.2.0/24) - For Private Endpoints
# -----------------------------------------------------------------------------

resource "azurerm_subnet" "private" {
  name                 = "snet-${local.naming_prefix}-private"
  resource_group_name  = local.resource_group_name_final
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [local.private_subnet_cidr]
  
  service_endpoints = var.private_subnet_service_endpoints
  
  # Disable network policies for private endpoints (required)
  private_endpoint_network_policies_enabled     = false
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_subnet_route_table_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  route_table_id = azurerm_route_table.private.id
}

# -----------------------------------------------------------------------------
# APPLICATION SUBNET (10.x.3.0/24)
# -----------------------------------------------------------------------------

resource "azurerm_subnet" "application" {
  name                 = "snet-${local.naming_prefix}-app"
  resource_group_name  = local.resource_group_name_final
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [local.application_subnet_cidr]
  
  service_endpoints = var.application_subnet_service_endpoints
  
  private_endpoint_network_policies_enabled     = var.enable_private_endpoint_network_policies
  private_link_service_network_policies_enabled = var.enable_service_endpoint_network_policies
}

resource "azurerm_subnet_network_security_group_association" "application" {
  subnet_id                 = azurerm_subnet.application.id
  network_security_group_id = azurerm_network_security_group.application.id
}

resource "azurerm_subnet_route_table_association" "application" {
  subnet_id      = azurerm_subnet.application.id
  route_table_id = azurerm_route_table.application.id
}

# -----------------------------------------------------------------------------
# AKS SUBNET (10.x.4.0/22) - Optional
# -----------------------------------------------------------------------------

resource "azurerm_subnet" "aks" {
  count = var.enable_aks_subnet ? 1 : 0
  
  name                 = "snet-${local.naming_prefix}-aks"
  resource_group_name  = local.resource_group_name_final
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [local.aks_subnet_cidr]
  
  service_endpoints = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
  
  private_endpoint_network_policies_enabled     = false
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  count = var.enable_aks_subnet ? 1 : 0
  
  subnet_id                 = azurerm_subnet.aks[0].id
  network_security_group_id = azurerm_network_security_group.aks[0].id
}

resource "azurerm_subnet_route_table_association" "aks" {
  count = var.enable_aks_subnet ? 1 : 0
  
  subnet_id      = azurerm_subnet.aks[0].id
  route_table_id = azurerm_route_table.aks[0].id
}

# =============================================================================
# VNET PEERING (Spoke ↔ Hub)
# =============================================================================

# Spoke to Hub peering
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-${local.naming_prefix}-to-hub"
  resource_group_name       = local.resource_group_name_final
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = var.hub_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.allow_gateway_transit
  use_remote_gateways          = var.use_remote_gateways && var.enable_vpn_gateway
  
  depends_on = [
    azurerm_virtual_network.spoke,
    azurerm_route_table.database,
    azurerm_route_table.private,
    azurerm_route_table.application
  ]
}

# Hub to Spoke peering
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = local.hub_to_spoke_peering_name
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = !var.allow_gateway_transit # Hub provides gateway
  use_remote_gateways          = false
  
  depends_on = [
    azurerm_virtual_network_peering.spoke_to_hub
  ]
}

# =============================================================================
# PRIVATE DNS ZONE VNET LINKS (Link Spoke to Hub's DNS zones)
# =============================================================================

resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  for_each = var.enable_private_dns_integration ? var.private_dns_zone_ids : {}
  
  name                  = "link-${var.spoke_name}-${each.key}"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = split("/", each.value)[8] # Extract zone name from ID
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
  
  tags = local.common_tags
  
  depends_on = [
    azurerm_virtual_network_peering.spoke_to_hub
  ]
}

# =============================================================================
# DIAGNOSTIC SETTINGS (Send logs to Management LAW)
# =============================================================================

# VNet diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "diag-${local.vnet_name}"
  target_resource_id         = azurerm_virtual_network.spoke.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# NSG diagnostic settings (Database)
resource "azurerm_monitor_diagnostic_setting" "nsg_database" {
  name                       = "diag-${local.nsg_database_name}"
  target_resource_id         = azurerm_network_security_group.database.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }
  
  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

# NSG diagnostic settings (Private)
resource "azurerm_monitor_diagnostic_setting" "nsg_private" {
  name                       = "diag-${local.nsg_private_name}"
  target_resource_id         = azurerm_network_security_group.private.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }
  
  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

# NSG diagnostic settings (Application)
resource "azurerm_monitor_diagnostic_setting" "nsg_application" {
  name                       = "diag-${local.nsg_application_name}"
  target_resource_id         = azurerm_network_security_group.application.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }
  
  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "azurerm_client_config" "current" {}