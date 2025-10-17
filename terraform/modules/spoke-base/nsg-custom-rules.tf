# =============================================================================
# DYNAMIC CUSTOM NSG RULES
# =============================================================================
# Purpose: Apply customer-specific NSG rules dynamically per subnet
# Input: var.custom_nsg_rules (from tfvars)
# Structure: { database = [...], private = [...], application = [...], aks = [...] }
# =============================================================================

# -----------------------------------------------------------------------------
# DATABASE SUBNET - Custom Rules
# -----------------------------------------------------------------------------

resource "azurerm_network_security_rule" "database_custom" {
  for_each = { for idx, rule in lookup(var.custom_nsg_rules, "database", []) : rule.name => rule }
  
  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.database.name
  
  depends_on = [azurerm_network_security_group.database]
}

# -----------------------------------------------------------------------------
# PRIVATE SUBNET - Custom Rules
# -----------------------------------------------------------------------------

resource "azurerm_network_security_rule" "private_custom" {
  for_each = { for idx, rule in lookup(var.custom_nsg_rules, "private", []) : rule.name => rule }
  
  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.private.name
  
  depends_on = [azurerm_network_security_group.private]
}

# -----------------------------------------------------------------------------
# APPLICATION SUBNET - Custom Rules
# -----------------------------------------------------------------------------

resource "azurerm_network_security_rule" "application_custom" {
  for_each = { for idx, rule in lookup(var.custom_nsg_rules, "application", []) : rule.name => rule }
  
  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.application.name
  
  depends_on = [azurerm_network_security_group.application]
}

# -----------------------------------------------------------------------------
# AKS SUBNET - Custom Rules (if enabled)
# -----------------------------------------------------------------------------

resource "azurerm_network_security_rule" "aks_custom" {
  for_each = var.enable_aks_subnet ? { for idx, rule in lookup(var.custom_nsg_rules, "aks", []) : rule.name => rule } : {}
  
  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = local.resource_group_name_final
  network_security_group_name = azurerm_network_security_group.aks[0].name
  
  depends_on = [azurerm_network_security_group.aks]
}