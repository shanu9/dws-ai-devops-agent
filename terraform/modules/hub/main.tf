# =============================================================================
# AZURE CAF-LZ HUB MODULE
# =============================================================================
# Purpose: Deploy Hub infrastructure for Hub-Spoke topology
# Components: VNet, Firewall, Bastion, VPN Gateway, DNS, Network Watcher
# Best Practices: Cost optimization, security, monitoring, high availability
# =============================================================================

# -----------------------------------------------------------------------------
# LOCAL VARIABLES - Naming Convention & Calculated Values
# -----------------------------------------------------------------------------

locals {
  # Naming convention: <resource-type>-<customer-id>-hub-<region-code>
  # Example: rg-abc-hub-eus, vnet-abc-hub-eus
  naming_prefix = "${var.customer_id}-hub-${var.region_code}"
  
  # Resource names following Azure naming best practices
  resource_group_name    = "rg-${local.naming_prefix}"
  vnet_name              = "vnet-${local.naming_prefix}"
  firewall_name          = "afw-${local.naming_prefix}"
  firewall_policy_name   = "afwp-${local.naming_prefix}"
  bastion_name           = "bas-${local.naming_prefix}"
  vpn_gateway_name       = "vpng-${local.naming_prefix}"
  network_watcher_name   = "nw-${local.naming_prefix}"
  
  # Public IP names
  firewall_pip_name = "pip-afw-${local.naming_prefix}"
  bastion_pip_name  = "pip-bas-${local.naming_prefix}"
  vpn_pip_name      = "pip-vpng-${local.naming_prefix}"
  
  # Subnet calculations (if not provided)
  vnet_cidr = var.hub_vnet_address_space[0]
  
  firewall_subnet_cidr = coalesce(
    var.firewall_subnet_prefix,
    cidrsubnet(local.vnet_cidr, 10, 0) # 10.0.0.0/26 if VNet is 10.0.0.0/16
  )
  
  bastion_subnet_cidr = coalesce(
    var.bastion_subnet_prefix,
    cidrsubnet(local.vnet_cidr, 10, 1) # 10.0.0.64/26
  )
  
  gateway_subnet_cidr = coalesce(
    var.gateway_subnet_prefix,
    cidrsubnet(local.vnet_cidr, 11, 4) # 10.0.0.128/27
  )
  
  # Comprehensive tagging strategy for cost tracking and governance
  common_tags = merge(
    {
      # Mandatory tags for cost allocation
      Customer      = var.customer_id
      Environment   = var.environment
      ManagedBy     = "Terraform"
      Component     = "Hub"
      CostCenter    = "Platform-${var.customer_id}"
      
      # Operational tags
      DeploymentDate = formatdate("YYYY-MM-DD", timestamp())
      Region         = var.region
      
      # Cost optimization tags
      AutoShutdown     = "false" # Hub resources always on
      BackupEnabled    = "true"
      MonitoringLevel  = "Critical"
      
      # Compliance tags
      DataClassification = "Internal"
      Compliance         = "CAF-LZ"
    },
    var.tags,
    var.mandatory_tags # Cannot be overridden
  )
}

# -----------------------------------------------------------------------------
# RESOURCE GROUP
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "hub" {
  name     = local.resource_group_name
  location = var.region
  tags     = local.common_tags
  
  lifecycle {
    ignore_changes = [
      tags["DeploymentDate"] # Prevent updates on every apply
    ]
  }
}

# -----------------------------------------------------------------------------
# HUB VIRTUAL NETWORK
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "hub" {
  name                = local.vnet_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = var.hub_vnet_address_space

  tags = merge(
    local.common_tags,
    {
      Name = local.vnet_name
      Purpose = "Hub network for centralized connectivity"
    }
  )
  
  # Best practice: Prevent accidental deletion
  lifecycle {
    prevent_destroy = false # Set to true in production
  }
  
 
}

# DDoS Protection Plan (Optional - High Cost)
resource "azurerm_network_ddos_protection_plan" "hub" {
  count = var.enable_ddos_protection ? 1 : 0
  
  name                = "ddos-${local.naming_prefix}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  
  tags = merge(
    local.common_tags,
    {
      Name = "ddos-${local.naming_prefix}"
      CostImpact = "High" # Flag for cost monitoring
    }
  )
}

# Network Watcher (Monitoring & Diagnostics)
resource "azurerm_network_watcher" "hub" {
  count = var.enable_network_watcher ? 1 : 0
  
  name                = local.network_watcher_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SUBNETS
# -----------------------------------------------------------------------------

# Azure Firewall Subnet (Must be named "AzureFirewallSubnet")
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.firewall_subnet_cidr]
  
  # Security: No service endpoints or delegations
}

# Azure Bastion Subnet (Must be named "AzureBastionSubnet")
resource "azurerm_subnet" "bastion" {
  count = var.enable_bastion ? 1 : 0
  
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.bastion_subnet_cidr]
}

# VPN Gateway Subnet (Must be named "GatewaySubnet")
resource "azurerm_subnet" "gateway" {
  count = var.enable_vpn_gateway ? 1 : 0
  
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [local.gateway_subnet_cidr]
}

# -----------------------------------------------------------------------------
# AZURE FIREWALL - Network Security Hub
# -----------------------------------------------------------------------------

# Public IP for Firewall
resource "azurerm_public_ip" "firewall" {
  name                = local.firewall_pip_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.enable_zone_redundancy ? var.firewall_availability_zones : []
  
  tags = merge(
    local.common_tags,
    {
      Name    = local.firewall_pip_name
      Purpose = "Firewall public IP for outbound traffic"
    }
  )
}

# Firewall Policy (Best Practice: Separate policy from firewall)
resource "azurerm_firewall_policy" "hub" {
  name                = local.firewall_policy_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = var.firewall_sku_tier
  
  # DNS settings
  dns {
    proxy_enabled = var.enable_firewall_dns_proxy
    servers       = var.firewall_dns_servers
  }
  
  # Threat Intelligence
  threat_intelligence_mode = var.firewall_threat_intel_mode
  
  # Intrusion Detection (Premium SKU only)
  dynamic "intrusion_detection" {
    for_each = var.firewall_sku_tier == "Premium" ? [1] : []
    content {
      mode = "Alert" # Alert mode for monitoring
    }
  }
  
  tags = local.common_tags
}

# Azure Firewall
resource "azurerm_firewall" "hub" {
  name                = local.firewall_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.hub.id
  zones               = var.enable_zone_redundancy ? var.firewall_availability_zones : []
  
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
  
  tags = merge(
    local.common_tags,
    {
      Name           = local.firewall_name
      Purpose        = "Centralized network security and traffic filtering"
      CriticalityLevel = "Critical"
    }
  )
  
  depends_on = [
    azurerm_public_ip.firewall,
    azurerm_firewall_policy.hub
  ]
}

# Diagnostic Settings for Firewall (Cost Intelligence Data Source)
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "diag-${local.firewall_name}"
  target_resource_id         = azurerm_firewall.hub.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  # Firewall Logs (Essential for cost analysis and security)
  enabled_log {
    category = "AzureFirewallApplicationRule"
  }
  
  enabled_log {
    category = "AzureFirewallNetworkRule"
  }
  
  enabled_log {
    category = "AzureFirewallDnsProxy"
  }
  
  # Metrics for performance monitoring
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# -----------------------------------------------------------------------------
# AZURE BASTION - Secure VM Access
# -----------------------------------------------------------------------------

# Public IP for Bastion
resource "azurerm_public_ip" "bastion" {
  count = var.enable_bastion ? 1 : 0
  
  name                = local.bastion_pip_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.enable_zone_redundancy ? ["1", "2", "3"] : []
  
  tags = merge(
    local.common_tags,
    {
      Name    = local.bastion_pip_name
      Purpose = "Bastion secure access"
    }
  )
}

# Azure Bastion
resource "azurerm_bastion_host" "hub" {
  count = var.enable_bastion ? 1 : 0
  
  name                = local.bastion_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = var.bastion_sku
  scale_units         = var.bastion_sku == "Standard" ? var.bastion_scale_units : 2
  
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
  
  tags = merge(
    local.common_tags,
    {
      Name    = local.bastion_name
      Purpose = "Secure RDP/SSH access without public IPs on VMs"
    }
  )
  
  depends_on = [
    azurerm_public_ip.bastion,
    azurerm_subnet.bastion
  ]
}

# Diagnostic Settings for Bastion
resource "azurerm_monitor_diagnostic_setting" "bastion" {
  count = var.enable_bastion ? 1 : 0
  
  name                       = "diag-${local.bastion_name}"
  target_resource_id         = azurerm_bastion_host.hub[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "BastionAuditLogs"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
resource "azurerm_virtual_network_dns_servers" "hub" {
  count = var.enable_firewall_dns_proxy ? 1 : 0
  
  virtual_network_id = azurerm_virtual_network.hub.id
  dns_servers        = [azurerm_firewall.hub.ip_configuration[0].private_ip_address]
}
# -----------------------------------------------------------------------------
# VPN GATEWAY - On-Premises Connectivity
# -----------------------------------------------------------------------------

# Public IP for VPN Gateway
resource "azurerm_public_ip" "vpn" {
  count = var.enable_vpn_gateway ? 1 : 0
  
  name                = local.vpn_pip_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.enable_zone_redundancy && contains(["VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ"], var.vpn_gateway_sku) ? ["1", "2", "3"] : []
  
  tags = merge(
    local.common_tags,
    {
      Name    = local.vpn_pip_name
      Purpose = "VPN Gateway public IP"
    }
  )
}

# VPN Gateway
resource "azurerm_virtual_network_gateway" "vpn" {
  count = var.enable_vpn_gateway ? 1 : 0
  
  name                = local.vpn_gateway_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  
  type     = var.vpn_gateway_type
  vpn_type = "RouteBased"
  
  active_active = false # Cost optimization: Single instance
  enable_bgp    = true  # Best practice: Enable BGP for dynamic routing
  sku           = var.vpn_gateway_sku
  generation    = var.vpn_gateway_generation
  
  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway[0].id
  }
  
  tags = merge(
    local.common_tags,
    {
      Name    = local.vpn_gateway_name
      Purpose = "Site-to-site VPN for on-premises connectivity"
    }
  )
  
  depends_on = [
    azurerm_public_ip.vpn,
    azurerm_subnet.gateway
  ]
}

# Diagnostic Settings for VPN Gateway
resource "azurerm_monitor_diagnostic_setting" "vpn" {
  count = var.enable_vpn_gateway ? 1 : 0
  
  name                       = "diag-${local.vpn_gateway_name}"
  target_resource_id         = azurerm_virtual_network_gateway.vpn[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "GatewayDiagnosticLog"
  }
  
  enabled_log {
    category = "TunnelDiagnosticLog"
  }
  
  enabled_log {
    category = "RouteDiagnosticLog"
  }
  
  enabled_log {
    category = "IKEDiagnosticLog"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# -----------------------------------------------------------------------------
# PRIVATE DNS ZONES - For Private Endpoints
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "hub" {
  for_each = var.enable_private_dns_zones ? toset(var.private_dns_zones) : []
  
  name                = each.value
  resource_group_name = azurerm_resource_group.hub.name
  
 
  tags = {
    Customer    = var.customer_id
    Environment = var.environment
    ManagedBy   = "Terraform"
    Component   = "Hub-DNS"
    Purpose     = "Private-DNS"
  }
}

# Link DNS Zones to Hub VNet
resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  for_each = var.enable_private_dns_zones ? toset(var.private_dns_zones) : []
  
  name                  = "link-${local.vnet_name}"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.hub[each.key].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false # Manual registration only
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS - VNet Flow Logs (Cost Intelligence)
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "diag-${local.vnet_name}"
  target_resource_id         = azurerm_virtual_network.hub.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}