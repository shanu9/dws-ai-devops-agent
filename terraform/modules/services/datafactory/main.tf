# =============================================================================
# AZURE DATA FACTORY MODULE
# =============================================================================

locals {
  naming_prefix = "${var.customer_id}-${var.spoke_name}-${var.region_code}"
  data_factory_name = coalesce(
    var.data_factory_name,
    "adf-${local.naming_prefix}"
  )
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Data-Factory"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# DATA FACTORY
# -----------------------------------------------------------------------------

resource "azurerm_data_factory" "main" {
  name                = local.data_factory_name
  location            = var.region
  resource_group_name = var.resource_group_name
  
  public_network_enabled          = var.public_network_enabled
  managed_virtual_network_enabled = var.managed_virtual_network_enabled
  customer_managed_key_id         = var.customer_managed_key_id
  
  identity {
    type = "SystemAssigned"
  }
  
  dynamic "github_configuration" {
    for_each = var.enable_git_integration && var.git_config != null && var.git_config.type == "GitHub" ? [1] : []
    content {
      account_name    = var.git_config.account_name
      branch_name     = var.git_config.branch_name
      repository_name = var.git_config.repository_name
      root_folder     = var.git_config.root_folder
    }
  }
  
  dynamic "vsts_configuration" {
    for_each = var.enable_git_integration && var.git_config != null && var.git_config.type == "AzureDevOps" ? [1] : []
    content {
      account_name    = var.git_config.account_name
      branch_name     = var.git_config.branch_name
      project_name    = var.git_config.repository_name
      repository_name = var.git_config.repository_name
      root_folder     = var.git_config.root_folder
      tenant_id       = data.azurerm_client_config.current.tenant_id
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# AZURE INTEGRATION RUNTIME (Managed VNet)
# -----------------------------------------------------------------------------

resource "azurerm_data_factory_integration_runtime_azure" "main" {
  count = var.enable_azure_ir ? 1 : 0
  
  name            = "ir-azure-${local.naming_prefix}"
  data_factory_id = azurerm_data_factory.main.id
  location        = var.region
  
  compute_type    = var.azure_ir_compute_type
  core_count      = var.azure_ir_core_count
  time_to_live_min = var.azure_ir_time_to_live
  
  virtual_network_enabled = var.managed_virtual_network_enabled
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "datafactory" {
  name                = "pe-${local.data_factory_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.data_factory_name}"
    private_connection_resource_id = azurerm_data_factory.main.id
    is_manual_connection           = false
    subresource_names              = ["dataFactory"]
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

resource "azurerm_monitor_diagnostic_setting" "datafactory" {
  name                       = "diag-${local.data_factory_name}"
  target_resource_id         = azurerm_data_factory.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "ActivityRuns"
  }
  
  enabled_log {
    category = "PipelineRuns"
  }
  
  enabled_log {
    category = "TriggerRuns"
  }
  
  enabled_log {
    category = "SandboxPipelineRuns"
  }
  
  enabled_log {
    category = "SandboxActivityRuns"
  }
  
  metric {
    category = "AllMetrics"
  }
}

data "azurerm_client_config" "current" {}