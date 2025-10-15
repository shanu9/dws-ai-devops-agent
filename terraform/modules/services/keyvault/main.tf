# =============================================================================
# AZURE KEY VAULT MODULE
# =============================================================================

locals {
  naming_prefix = "${var.customer_id}-${var.spoke_name}-${var.region_code}"
  # Key Vault names: max 24 chars, alphanumeric + hyphens
  keyvault_name = coalesce(
    var.keyvault_name,
    substr("kv-${var.customer_id}-${var.spoke_name}-${var.region_code}", 0, 24)
  )
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Key-Vault"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# KEY VAULT
# -----------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                = local.keyvault_name
  location            = var.region
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name
  
  # Security settings
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled
  enable_rbac_authorization  = var.enable_rbac_authorization
  
  # Network security
  public_network_access_enabled = var.public_network_access_enabled
  
  network_acls {
    bypass         = var.bypass_azure_services ? "AzureServices" : "None"
    default_action = "Deny"
    ip_rules       = var.allowed_ip_ranges
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ACCESS POLICIES (if not using RBAC)
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_access_policy" "policies" {
  for_each = var.enable_rbac_authorization ? {} : var.access_policies
  
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id
  
  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  certificate_permissions = each.value.certificate_permissions
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-${local.keyvault_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.keyvault_name}"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
  
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-${local.keyvault_name}"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "AuditEvent"
  }
  
  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }
  
  metric {
    category = "AllMetrics"
  }
}