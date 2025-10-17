# =============================================================================
# AZURE FIREWALL - DYNAMIC RULE COLLECTION GROUPS
# =============================================================================
# Purpose: Apply customer-specific firewall rules dynamically
# Input: var.firewall_rules (from tfvars)
# Best Practice: Separate default rules from custom customer rules
# =============================================================================

# -----------------------------------------------------------------------------
# DEFAULT FIREWALL RULES (Safe baseline for all customers)
# -----------------------------------------------------------------------------

resource "azurerm_firewall_policy_rule_collection_group" "default" {
  count = var.enable_default_firewall_rules ? 1 : 0
  
  name               = "default-rules"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 100

  # -------------------------------------------------------------------------
  # APPLICATION RULES - Allow essential Azure services
  # -------------------------------------------------------------------------
  
  application_rule_collection {
    name     = "allow-azure-services"
    priority = 110
    action   = "Allow"

    rule {
      name = "allow-windows-update"
      source_addresses = ["*"]
      destination_fqdns = [
        "*.windowsupdate.microsoft.com",
        "*.update.microsoft.com",
        "*.windowsupdate.com",
        "*.download.windowsupdate.com",
        "*.download.microsoft.com",
        "*.dl.delivery.mp.microsoft.com",
        "*.prod.do.dsp.mp.microsoft.com"
      ]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name = "allow-azure-management"
      source_addresses = ["*"]
      destination_fqdns = [
        "*.azure.com",
        "*.microsoft.com",
        "*.microsoftonline.com",
        "*.windows.net",
        "*.azurecr.io",
        "management.azure.com",
        "login.microsoftonline.com",
        "*.azure-automation.net"
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name = "allow-ubuntu-updates"
      source_addresses = ["*"]
      destination_fqdns = [
        "*.ubuntu.com",
        "archive.ubuntu.com",
        "security.ubuntu.com"
      ]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  # -------------------------------------------------------------------------
  # NETWORK RULES - Allow DNS, NTP, ICMP
  # -------------------------------------------------------------------------
  
  network_rule_collection {
    name     = "allow-infrastructure"
    priority = 200
    action   = "Allow"

    rule {
      name                  = "allow-dns"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "allow-ntp"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }

    rule {
      name                  = "allow-icmp"
      protocols             = ["ICMP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
  }

  network_rule_collection {
    name     = "allow-azure-monitor"
    priority = 210
    action   = "Allow"

    rule {
      name                  = "allow-log-analytics"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["443"]
    }
  }
}

# -----------------------------------------------------------------------------
# CUSTOM CUSTOMER RULES (Dynamic from tfvars)
# -----------------------------------------------------------------------------

resource "azurerm_firewall_policy_rule_collection_group" "custom" {
  count = length(var.firewall_rules.application_rules) > 0 || length(var.firewall_rules.network_rules) > 0 ? 1 : 0
  
  name               = "customer-rules"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 500  # Higher priority than defaults

  # -------------------------------------------------------------------------
  # DYNAMIC APPLICATION RULES
  # -------------------------------------------------------------------------
  
  dynamic "application_rule_collection" {
    for_each = { for idx, rule in var.firewall_rules.application_rules : idx => rule }
    
    content {
      name     = "app-${application_rule_collection.value.name}"
      priority = application_rule_collection.value.priority
      action   = "Allow"
      
      rule {
        name              = application_rule_collection.value.name
        source_addresses  = application_rule_collection.value.source_addresses
        destination_fqdns = application_rule_collection.value.destination_fqdns
        
        dynamic "protocols" {
          for_each = application_rule_collection.value.protocols
          
          content {
            type = protocols.value.type
            port = protocols.value.port
          }
        }
      }
    }
  }

  # -------------------------------------------------------------------------
  # DYNAMIC NETWORK RULES
  # -------------------------------------------------------------------------
  
  dynamic "network_rule_collection" {
    for_each = { for idx, rule in var.firewall_rules.network_rules : idx => rule }
    
    content {
      name     = "net-${network_rule_collection.value.name}"
      priority = network_rule_collection.value.priority
      action   = "Allow"
      
      rule {
        name                  = network_rule_collection.value.name
        protocols             = network_rule_collection.value.protocols
        source_addresses      = network_rule_collection.value.source_addresses
        destination_addresses = network_rule_collection.value.destination_addresses
        destination_ports     = network_rule_collection.value.destination_ports
      }
    }
  }
}