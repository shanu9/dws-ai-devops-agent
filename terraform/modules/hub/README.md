# Hub Module - Azure CAF Landing Zone

Deploys the Hub infrastructure for a Hub-Spoke network topology, providing centralized connectivity, security, and management for all Spoke environments.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Components](#components)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Cost Optimization](#cost-optimization)
- [Security Best Practices](#security-best-practices)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## 🏗️ Overview

The Hub module creates the central network hub that:
- **Centralizes connectivity** - All traffic routes through the Hub
- **Enforces security** - Azure Firewall filters all outbound traffic
- **Enables secure access** - Azure Bastion provides secure RDP/SSH
- **Connects on-premises** - VPN Gateway for hybrid connectivity
- **Manages DNS** - Private DNS zones for Azure services

### Key Features

✅ **Production-Ready** - Enterprise-grade infrastructure  
✅ **Cost-Optimized** - Configurable SKUs and optional components  
✅ **Highly Available** - Zone redundancy for 99.99% SLA  
✅ **Fully Monitored** - Integrated diagnostics to Log Analytics  
✅ **Security-First** - Zero Trust principles, threat intelligence  
✅ **Compliant** - Follows Azure CAF best practices  

---

## 🏛️ Architecture
┌─────────────────────────────────────────────────────┐
│                   Hub Subscription                  │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │           Hub VNet (10.0.0.0/16)              │ │
│  │                                               │ │
│  │  ┌─────────────────┐  ┌──────────────────┐  │ │
│  │  │ Firewall Subnet │  │ Bastion Subnet   │  │ │
│  │  │   (10.0.0.0/26) │  │  (10.0.0.64/26)  │  │ │
│  │  │                 │  │                  │  │ │
│  │  │  Azure Firewall │  │  Azure Bastion   │  │ │
│  │  │  (Private IP)   │  │                  │  │ │
│  │  │  ↓ Next Hop     │  │  Secure Access   │  │ │
│  │  └─────────────────┘  └──────────────────┘  │ │
│  │                                               │ │
│  │  ┌──────────────────┐                        │ │
│  │  │ Gateway Subnet   │                        │ │
│  │  │ (10.0.0.128/27)  │                        │ │
│  │  │                  │                        │ │
│  │  │  VPN Gateway     │                        │ │
│  │  │  (On-Premises)   │                        │ │
│  │  └──────────────────┘                        │ │
│  │                                               │ │
│  │  ┌────────────────────────────────────────┐  │ │
│  │  │      Private DNS Zones (20+)           │  │ │
│  │  │  privatelink.blob.core.windows.net     │  │ │
│  │  │  privatelink.database.windows.net      │  │ │
│  │  │  privatelink.openai.azure.com          │  │ │
│  │  │  ... (linked to Hub VNet)              │  │ │
│  │  └────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │          Network Watcher                      │ │
│  │  - Flow Logs      - Connection Monitor       │ │
│  │  - Packet Capture - Network Diagnostics      │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
│
│ VNet Peering
↓
┌─────────────────────┐
│  Spoke VNets        │
│  (All traffic via   │
│   Firewall)         │
└─────────────────────┘

---

## 📦 Components

### Core Components (Always Deployed)

| Component | Purpose | SKU | Cost Impact |
|-----------|---------|-----|-------------|
| **Hub VNet** | Central network hub | N/A | Low |
| **Azure Firewall** | Network security & filtering | Standard/Premium | High |
| **Firewall Policy** | Centralized firewall rules | N/A | Low |
| **Public IP (Firewall)** | Outbound connectivity | Standard | Low |
| **Private DNS Zones** | Private endpoint DNS | N/A | Low |

### Optional Components

| Component | Purpose | Default | Cost Impact |
|-----------|---------|---------|-------------|
| **Azure Bastion** | Secure VM access | Enabled | Medium |
| **VPN Gateway** | On-premises connectivity | Disabled | High |
| **DDoS Protection** | DDoS mitigation | Disabled | Very High |
| **Network Watcher** | Network monitoring | Enabled | Low |
| **Zone Redundancy** | High availability | Enabled | Medium |

---

## ✅ Prerequisites

### Azure Requirements

1. **Azure Subscription**
   - Owner or Contributor role
   - Resource Provider registered: `Microsoft.Network`, `Microsoft.Insights`

2. **Management Subscription**
   - Log Analytics Workspace deployed (from Management module)
   - Workspace ID available

3. **Naming Standards**
   - Customer ID: 3-6 lowercase alphanumeric characters
   - Region code: 2-4 lowercase letters (e.g., `eus`, `jpe`)

### Terraform Requirements
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

🚀 Usage
Basic Usage (Minimum Configuration)
hclmodule "hub" {
  source = "../../modules/hub"
  
  # Required variables
  customer_id    = "abc"
  environment    = "prd"
  region         = "eastus"
  region_code    = "eus"
  
  # Network configuration
  hub_vnet_address_space = ["10.0.0.0/16"]
  
  # Monitoring (from Management module)
  log_analytics_workspace_id = module.management.workspace_id
  
  # Tags
  tags = {
    Project     = "CAF-LZ"
    Owner       = "Platform-Team"
    CostCenter  = "IT-Infrastructure"
  }
}
Production Configuration (Full Features)
hclmodule "hub" {
  source = "../../modules/hub"
  
  # Identity
  customer_id = "contoso"
  environment = "prd"
  region      = "eastus"
  region_code = "eus"
  
  # Network
  hub_vnet_address_space  = ["10.0.0.0/16"]
  firewall_subnet_prefix  = "10.0.0.0/26"
  bastion_subnet_prefix   = "10.0.0.64/26"
  gateway_subnet_prefix   = "10.0.0.128/27"
  
  # Firewall Configuration
  firewall_sku_tier          = "Premium"  # TLS inspection, IDPS
  firewall_threat_intel_mode = "Deny"     # Block threats
  enable_firewall_dns_proxy  = true
  firewall_availability_zones = ["1", "2", "3"]
  
  # Bastion Configuration
  enable_bastion       = true
  bastion_sku          = "Standard"  # Native client, file transfer
  bastion_scale_units  = 4           # Higher capacity
  
  # VPN Gateway (On-premises connectivity)
  enable_vpn_gateway      = true
  vpn_gateway_sku         = "VpnGw2AZ"  # Zone redundant
  vpn_gateway_generation  = "Generation2"
  
  # Private DNS
  enable_private_dns_zones = true
  # Uses default 20+ DNS zones
  
  # Monitoring
  log_analytics_workspace_id   = module.management.workspace_id
  diagnostic_log_retention_days = 90
  enable_network_watcher        = true
  
  # High Availability
  enable_zone_redundancy = true
  
  # Security
  enable_ddos_protection = true  # For critical production
  allowed_management_ips = [
    "203.0.113.0/24"  # Your office IP range
  ]
  
  # Tags
  tags = {
    Project       = "Enterprise-Hub"
    Owner         = "Network-Team"
    CostCenter    = "NetOps"
    Criticality   = "Critical"
    Compliance    = "ISO27001"
  }
}
Cost-Optimized Configuration (Dev/Test)
hclmodule "hub" {
  source = "../../modules/hub"
  
  # Identity
  customer_id = "dev"
  environment = "dev"
  region      = "eastus"
  region_code = "eus"
  
  # Network
  hub_vnet_address_space = ["10.0.0.0/16"]
  
  # Firewall - Standard tier (lower cost)
  firewall_sku_tier          = "Standard"
  firewall_availability_zones = []  # No zones = lower cost
  
  # Bastion - Basic tier
  enable_bastion      = true
  bastion_sku         = "Basic"
  bastion_scale_units = 2  # Minimum
  
  # VPN - Disabled (not needed for dev)
  enable_vpn_gateway = false
  
  # DDoS - Disabled (save ~$3000/month)
  enable_ddos_protection = false
  
  # High Availability - Disabled for dev
  enable_zone_redundancy = false
  
  # Monitoring
  log_analytics_workspace_id   = module.management.workspace_id
  diagnostic_log_retention_days = 30  # Shorter retention
  
  tags = {
    Environment = "Development"
    AutoShutdown = "Allowed"
  }
}

📥 Inputs
Required Inputs
NameTypeDescriptioncustomer_idstringUnique customer identifier (3-6 chars)regionstringAzure region (e.g., eastus)region_codestringShort region code (e.g., eus)log_analytics_workspace_idstringLog Analytics Workspace ID from Management module
Network Configuration
NameTypeDefaultDescriptionenvironmentstring"prd"Environment: dev/stg/prdhub_vnet_address_spacelist(string)["10.0.0.0/16"]Hub VNet CIDRfirewall_subnet_prefixstringAuto-calculatedFirewall subnet (min /26)bastion_subnet_prefixstringAuto-calculatedBastion subnet (min /26)gateway_subnet_prefixstringAuto-calculatedVPN Gateway subnet (min /27)
Firewall Configuration
NameTypeDefaultDescriptionfirewall_sku_tierstring"Standard"Standard or Premiumfirewall_threat_intel_modestring"Alert"Off/Alert/Denyenable_firewall_dns_proxybooltrueEnable DNS proxyfirewall_dns_serverslist(string)[]Custom DNS serversfirewall_availability_zoneslist(string)["1","2","3"]Availability zones
Bastion Configuration
NameTypeDefaultDescriptionenable_bastionbooltrueDeploy Bastionbastion_skustring"Basic"Basic or Standardbastion_scale_unitsnumber2Scale units (2-50)
VPN Gateway Configuration
NameTypeDefaultDescriptionenable_vpn_gatewayboolfalseDeploy VPN Gatewayvpn_gateway_skustring"VpnGw1"Gateway SKUvpn_gateway_generationstring"Generation2"Gen1 or Gen2
See variables.tf for complete list.

📤 Outputs
Key Outputs (Most Used)
OutputDescriptionUsagevnet_idHub VNet IDVNet peering from Spokesfirewall_private_ipFirewall private IPNext hop in route tableshub_configComplete Hub configurationSpoke module inputprivate_dns_zone_idsDNS zone IDsPrivate endpoint creation
All Outputs
hcl# Resource Group
output "resource_group_name"
output "resource_group_id"

# Virtual Network
output "vnet_id"
output "vnet_name"
output "vnet_address_space"

# Firewall (CRITICAL)
output "firewall_id"
output "firewall_private_ip"  # Use as next hop
output "firewall_policy_id"

# Bastion
output "bastion_id"
output "bastion_fqdn"

# VPN Gateway
output "vpn_gateway_id"
output "vpn_gateway_public_ip"

# Private DNS
output "private_dns_zones"
output "private_dns_zone_ids"

# Configuration Objects
output "hub_config"           # For Spoke modules
output "cost_tracking"        # For cost intelligence
output "security_config"      # For compliance
output "deployment_summary"   # Human-readable
See outputs.tf for complete documentation.

💰 Cost Optimization
Monthly Cost Estimates (USD)
ConfigurationFirewallBastionVPNDDoSTotal/MonthMinimum (Dev)$1,200$140$0$0~$1,400Standard (Prod)$1,200$140$140$0~$1,500Premium (Enterprise)$1,700$300$350$3,000~$5,400
Cost Optimization Tips
1. Firewall SKU Selection
hcl# Standard tier (sufficient for most use cases)
firewall_sku_tier = "Standard"  # $1,200/month

# Premium tier (only if you need TLS inspection or IDPS)
firewall_sku_tier = "Premium"   # $1,700/month
Savings: $500/month by using Standard
2. Disable Zone Redundancy in Dev/Test
hcl# Production: High availability
enable_zone_redundancy = true
firewall_availability_zones = ["1", "2", "3"]

# Dev/Test: Lower cost
enable_zone_redundancy = false
firewall_availability_zones = []
Savings: ~20% on Firewall costs
3. Bastion SKU Selection
hcl# Basic tier (standard features)
bastion_sku = "Basic"  # $140/month

# Standard tier (native client, file transfer)
bastion_sku = "Standard"  # $300/month
Savings: $160/month with Basic
4. Conditional VPN Gateway
hcl# Only deploy if on-premises connectivity needed
enable_vpn_gateway = var.has_on_premises  # Variable-driven

# Use lowest SKU that meets requirements
vpn_gateway_sku = "VpnGw1"  # $140/month
Savings: $140-350/month if not needed
5. DDoS Protection
hcl# Only enable for critical production
enable_ddos_protection = var.environment == "prd" && var.is_critical
Savings: $3,000/month by using Basic Protection
6. Log Retention
hcl# Shorter retention for non-production
diagnostic_log_retention_days = var.environment == "prd" ? 90 : 30
Savings: Storage costs on log data

🔒 Security Best Practices
1. Firewall Configuration
✅ Enable Threat Intelligence
hclfirewall_threat_intel_mode = "Deny"  # Block known threats
✅ Enable DNS Proxy
hclenable_firewall_dns_proxy = true  # Required for FQDN filtering
✅ Use Premium SKU for Sensitive Data
hclfirewall_sku_tier = "Premium"  # TLS inspection, IDPS
2. Network Segmentation
✅ Dedicated Subnets

Firewall: /26 minimum
Bastion: /26 minimum
Gateway: /27 minimum

✅ No NSGs on Special Subnets

Azure manages security for AzureFirewallSubnet, AzureBastionSubnet

3. Access Control
✅ Restrict Management Access
hclallowed_management_ips = [
  "203.0.113.0/24"  # Office IP range only
]
✅ Use Bastion for VM Access
hclenable_bastion = true  # No public IPs on VMs
4. Monitoring
✅ Enable All Diagnostic Logs

Firewall: Application rules, Network rules, DNS proxy
VPN Gateway: Gateway, Tunnel, Route, IKE logs
Bastion: Audit logs

✅ Send to Log Analytics
hcllog_analytics_workspace_id = module.management.workspace_id
5. High Availability
✅ Use Availability Zones
hclenable_zone_redundancy = true
firewall_availability_zones = ["1", "2", "3"]
✅ Zone-Redundant SKUs
hclvpn_gateway_sku = "VpnGw1AZ"  # Zone redundant

📚 Examples
Example 1: Multi-Region Hub
hcl# Primary Hub - East US
module "hub_primary" {
  source = "../../modules/hub"
  
  customer_id = "contoso"
  environment = "prd"
  region      = "eastus"
  region_code = "eus"
  
  hub_vnet_address_space = ["10.0.0.0/16"]
  
  # ... other config
}

# Secondary Hub - West US (DR)
module "hub_secondary" {
  source = "../../modules/hub"
  
  customer_id = "contoso"
  environment = "prd"
  region      = "westus"
  region_code = "wus"
  
  hub_vnet_address_space = ["10.1.0.0/16"]  # Different range
  
  # ... other config
}

# VNet peering between hubs (optional)
resource "azurerm_virtual_network_peering" "primary_to_secondary" {
  name                      = "peer-eus-to-wus"
  resource_group_name       = module.hub_primary.resource_group_name
  virtual_network_name      = module.hub_primary.vnet_name
  remote_virtual_network_id = module.hub_secondary.vnet_id
  
  allow_forwarded_traffic = true
}
Example 2: Conditional Features Based on Environment
hcllocals {
  is_production = var.environment == "prd"
}

module "hub" {
  source = "../../modules/hub"
  
  customer_id = var.customer_id
  environment = var.environment
  region      = var.region
  region_code = var.region_code
  
  # Conditional features
  firewall_sku_tier      = local.is_production ? "Premium" : "Standard"
  enable_zone_redundancy = local.is_production
  enable_ddos_protection = local.is_production
  
  # Conditional SKUs
  bastion_sku    = local.is_production ? "Standard" : "Basic"
  vpn_gateway_sku = local.is_production ? "VpnGw2AZ" : "VpnGw1"
  
  # Conditional retention
  diagnostic_log_retention_days = local.is_production ? 90 : 30
  
  log_analytics_workspace_id = var.workspace_id
}
Example 3: Hub with Custom DNS Zones
hclmodule "hub" {
  source = "../../modules/hub"
  
  # ... basic config
  
  # Enable private DNS with custom zones
  enable_private_dns_zones = true
  
  private_dns_zones = [
    # Azure services
    "privatelink.blob.core.windows.net",
    "privatelink.database.windows.net",
    "privatelink.openai.azure.com",
    
    # Custom on-premises zones
    "contoso.local",
    "corp.contoso.com"
  ]
  
  log_analytics_workspace_id = var.workspace_id
}

🔧 Troubleshooting
Issue: Firewall not routing traffic
Symptoms:

Spoke VMs cannot reach internet
Private endpoints not resolving

Solution:

Verify route table points to Firewall:

bashaz network route-table route show \
  --resource-group rg-spoke \
  --route-table-name rt-spoke \
  --name default-to-firewall

# Next hop should be: Firewall private IP

Check Firewall rules allow traffic:

bashaz network firewall policy rule-collection-group list \
  --resource-group rg-hub \
  --policy-name afwp-hub

Verify DNS proxy enabled:

bashaz network firewall show \
  --resource-group rg-hub \
  --name afw-hub \
  --query "additionalProperties.Network.DnsProxy"
Issue: Bastion connection fails
Symptoms:

Cannot connect to VMs via Bastion
Timeout errors

Solution:

Verify user permissions:

Reader on Bastion resource
Reader on target VM
Reader on VM's NIC


Check Bastion subnet NSG (should have no NSG):

bashaz network vnet subnet show \
  --resource-group rg-hub \
  --vnet-name vnet-hub \
  --name AzureBastionSubnet \
  --query "networkSecurityGroup"
# Should return: null

Verify Bastion status:

bashaz network bastion show \
  --resource-group rg-hub \
  --name bas-hub \
  --query "provisioningState"
# Should return: "Succeeded"
Issue: VPN Gateway not connecting
Symptoms:

On-premises to Azure connection fails
VPN tunnel down

Solution:

Verify on-premises device configuration matches:

bashaz network vnet-gateway show \
  --resource-group rg-hub \
  --name vpng-hub \
  --query "{PublicIP: bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0], ASN: bgpSettings.asn}"

Check VPN connection status:

bashaz network vpn-connection show \
  --resource-group rg-hub \
  --name conn-onprem \
  --query "connectionStatus"

Review logs in Log Analytics:

kustoAzureDiagnostics
| where Category == "IKEDiagnosticLog"
| where TimeGenerated > ago(1h)
| project TimeGenerated, Message
Issue: Private DNS not resolving
Symptoms:

Storage account resolves to public IP
Cannot access services privately

Solution:

Verify DNS zone linked to VNet:

bashaz network private-dns link vnet list \
  --resource-group rg-hub \
  --zone-name privatelink.blob.core.windows.net

Check VM DNS settings point to Firewall:

bashaz network vnet show \
  --resource-group rg-hub \
  --name vnet-hub \
  --query "dhcpOptions.dnsServers"
# Should return: [Firewall private IP]

Test DNS resolution from VM:

bashnslookup mystorageaccount.blob.core.windows.net
# Should return: 10.x.x.x (private IP)

📖 Additional Resources
Azure Documentation

Azure Hub-Spoke Topology
Azure Firewall Documentation
Azure Bastion Documentation
VPN Gateway Documentation

CAF Resources

Cloud Adoption Framework
Landing Zone Best Practices

Internal Documentation

Management Module
Spoke Module
Deployment Guide


📝 Notes
Naming Convention
All resources follow the pattern: <type>-<customer-id>-hub-<region-code>
Examples:

Resource Group: rg-contoso-hub-eus
VNet: vnet-contoso-hub-eus
Firewall: afw-contoso-hub-eus
Bastion: bas-contoso-hub-eus

Tagging Strategy
All resources include these tags:

Customer - Customer identifier
Environment - dev/stg/prd
Component - "Hub"
CostCenter - For cost allocation
ManagedBy - "Terraform"

Change Management
⚠️ Critical Resources - Handle with care:

Firewall (traffic impact)
VPN Gateway (connectivity impact)
DNS zones (resolution impact)

Always test changes in non-production first.

🤝 Contributing
For issues or improvements, contact the Platform Team.

📄 License
Copyright © 2025 Your Company. All rights reserved.

Version: 1.0.0
Last Updated: 2025-01-08
Maintained By: Platform Engineering Team

---

## **✅ Hub Module Complete!**

You now have **ALL 5 files** for the Hub module:

1. ✅ `versions.tf` - Provider requirements
2. ✅ `variables.tf` - 50+ input variables with validation
3. ✅ `main.tf` - Complete infrastructure code
4. ✅ `outputs.tf` - 85+ comprehensive outputs
5. ✅ `README.md` - Full documentation

### **Key Features Implemented:**

✅ **Production-Ready Code**
✅ **Cost Optimization Built-In**
✅ **Comprehensive Monitoring**
✅ **Security Best Practices**
✅ **High Availability**
✅ **Full Documentation**
✅ **Real-World Examples**
✅ **Troubleshooting Guide**