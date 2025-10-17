# =============================================================================
# AZURE COGNITIVE SERVICES MODULE
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

locals {
  naming_prefix = "${var.customer_id}-${var.spoke_name}-${var.region_code}"
  cognitive_account_name = coalesce(
    var.cognitive_account_name,
    "cog-${local.naming_prefix}"
  )
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Cognitive-Services"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# COGNITIVE SERVICES ACCOUNT
# -----------------------------------------------------------------------------

resource "azurerm_cognitive_account" "main" {
  name                = local.cognitive_account_name
  location            = var.region
  resource_group_name = var.resource_group_name
  kind                = var.kind
  sku_name            = var.sku_name
  
  # Custom subdomain (required for private endpoints)
  custom_subdomain_name = var.custom_subdomain_name != null ? var.custom_subdomain_name : local.cognitive_account_name
  
  # Public network access
  public_network_access_enabled = var.public_network_access_enabled
  
  # Network ACLs
  dynamic "network_acls" {
    for_each = var.public_network_access_enabled ? [1] : []
    content {
      default_action = "Deny"
      
      dynamic "ip_rules" {
        for_each = var.allowed_ip_ranges
        content {
          ip_range = ip_rules.value
        }
      }
      
      dynamic "virtual_network_rules" {
        for_each = var.allowed_subnet_ids
        content {
          subnet_id = virtual_network_rules.value
        }
      }
    }
  }
  
  # Customer-managed key
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key_id != null ? [1] : []
    content {
      key_vault_key_id   = var.customer_managed_key_id
      identity_client_id = var.key_vault_identity_client_id
    }
  }
  
  # Identity
  identity {
    type = var.customer_managed_key_id != null ? "SystemAssigned" : "SystemAssigned"
  }
  
  # Local authentication
  local_auth_enabled = var.enable_local_authentication
  
  # Outbound network access (for managed VNet)
  outbound_network_access_restricted = var.restrict_outbound_network_access
  
  # Dynamic throttling rules
  dynamic "dynamic_throttling_enabled" {
    for_each = var.enable_dynamic_throttling ? [1] : []
    content {
      dynamic_throttling_enabled = true
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# OPENAI DEPLOYMENTS (If kind is OpenAI)
# -----------------------------------------------------------------------------

resource "azurerm_cognitive_deployment" "openai" {
  for_each = var.kind == "OpenAI" ? var.openai_deployments : {}
  
  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.main.id
  
  model {
    format  = each.value.model_format
    name    = each.value.model_name
    version = each.value.model_version
  }
  
  scale {
    type     = each.value.scale_type
    capacity = each.value.scale_type == "Standard" ? each.value.capacity : null
  }
  
  rai_policy_name = each.value.rai_policy_name
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "cognitive" {
  count = var.enable_private_endpoint ? 1 : 0
  
  name                = "pe-${local.cognitive_account_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.cognitive_account_name}"
    private_connection_resource_id = azurerm_cognitive_account.main.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "pdz-group-cognitive"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "cognitive" {
  count = var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${local.cognitive_account_name}"
  target_resource_id         = azurerm_cognitive_account.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "Audit"
  }
  
  enabled_log {
    category = "RequestResponse"
  }
  
  enabled_log {
    category = "Trace"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}