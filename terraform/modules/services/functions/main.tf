# =============================================================================
# AZURE FUNCTIONS MODULE
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

locals {
  naming_prefix = "${var.customer_id}-${var.spoke_name}-${var.region_code}"
  function_app_name = coalesce(
    var.function_app_name,
    "func-${local.naming_prefix}"
  )
  storage_account_name = "funcst${replace(local.naming_prefix, "-", "")}${random_string.storage_suffix.result}"
  app_service_plan_name = "asp-${local.naming_prefix}"
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Azure-Functions"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# -----------------------------------------------------------------------------
# STORAGE ACCOUNT (Required for Functions)
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "functions" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# APP SERVICE PLAN (or Consumption Plan)
# -----------------------------------------------------------------------------

resource "azurerm_service_plan" "functions" {
  count = var.plan_type != "Consumption" ? 1 : 0
  
  name                = local.app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.region
  os_type             = var.os_type
  sku_name            = var.plan_sku
  
  # Elastic Premium features
  maximum_elastic_worker_count = var.plan_type == "ElasticPremium" ? var.max_elastic_workers : null
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# LINUX FUNCTION APP
# -----------------------------------------------------------------------------

resource "azurerm_linux_function_app" "main" {
  count = var.os_type == "Linux" ? 1 : 0
  
  name                       = local.function_app_name
  resource_group_name        = var.resource_group_name
  location                   = var.region
  service_plan_id            = var.plan_type != "Consumption" ? azurerm_service_plan.functions[0].id : null
  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  
  # Network configuration
  public_network_access_enabled      = var.public_network_access_enabled
  virtual_network_subnet_id          = var.vnet_integration_subnet_id
  
  # App settings
  app_settings = merge(
    var.app_settings,
    {
      "FUNCTIONS_WORKER_RUNTIME"       = var.runtime
      "WEBSITE_RUN_FROM_PACKAGE"       = "1"
      "APPINSIGHTS_INSTRUMENTATIONKEY" = var.app_insights_instrumentation_key
    }
  )
  
  # Site config
  site_config {
    always_on                              = var.plan_type != "Consumption" ? var.always_on : false
    application_insights_key               = var.app_insights_instrumentation_key
    application_insights_connection_string = var.app_insights_connection_string
    ftps_state                             = "FtpsOnly"
    http2_enabled                          = true
    minimum_tls_version                    = "1.2"
    
    # Runtime version
    dynamic "application_stack" {
      for_each = var.runtime != null ? [1] : []
      content {
        dynamic "node" {
          for_each = var.runtime == "node" ? [1] : []
          content {
            version = var.runtime_version
          }
        }
        dynamic "python" {
          for_each = var.runtime == "python" ? [1] : []
          content {
            version = var.runtime_version
          }
        }
        dynamic "dotnet" {
          for_each = var.runtime == "dotnet" ? [1] : []
          content {
            version = var.runtime_version
          }
        }
        dynamic "java" {
          for_each = var.runtime == "java" ? [1] : []
          content {
            version = var.runtime_version
          }
        }
      }
    }
    
    # CORS
    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins     = var.cors_allowed_origins
        support_credentials = var.cors_support_credentials
      }
    }
    
    # IP restrictions
    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        name       = ip_restriction.value.name
        ip_address = ip_restriction.value.ip_address
        priority   = ip_restriction.value.priority
        action     = ip_restriction.value.action
      }
    }
  }
  
  # Identity
  identity {
    type = "SystemAssigned"
  }
  
  # HTTPS only
  https_only = true
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# WINDOWS FUNCTION APP
# -----------------------------------------------------------------------------

resource "azurerm_windows_function_app" "main" {
  count = var.os_type == "Windows" ? 1 : 0
  
  name                       = local.function_app_name
  resource_group_name        = var.resource_group_name
  location                   = var.region
  service_plan_id            = var.plan_type != "Consumption" ? azurerm_service_plan.functions[0].id : null
  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  
  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_subnet_id     = var.vnet_integration_subnet_id
  
  app_settings = merge(
    var.app_settings,
    {
      "FUNCTIONS_WORKER_RUNTIME"       = var.runtime
      "WEBSITE_RUN_FROM_PACKAGE"       = "1"
      "APPINSIGHTS_INSTRUMENTATIONKEY" = var.app_insights_instrumentation_key
    }
  )
  
  site_config {
    always_on                              = var.plan_type != "Consumption" ? var.always_on : false
    application_insights_key               = var.app_insights_instrumentation_key
    application_insights_connection_string = var.app_insights_connection_string
    ftps_state                             = "FtpsOnly"
    http2_enabled                          = true
    minimum_tls_version                    = "1.2"
    
    dynamic "application_stack" {
      for_each = var.runtime != null ? [1] : []
      content {
        node_version    = var.runtime == "node" ? var.runtime_version : null
        python_version  = var.runtime == "python" ? var.runtime_version : null
        dotnet_version  = var.runtime == "dotnet" ? var.runtime_version : null
        java_version    = var.runtime == "java" ? var.runtime_version : null
        powershell_core_version = var.runtime == "powershell" ? var.runtime_version : null
      }
    }
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  https_only = true
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "functions" {
  count = var.enable_private_endpoint ? 1 : 0
  
  name                = "pe-${local.function_app_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  
  private_service_connection {
    name                           = "psc-${local.function_app_name}"
    private_connection_resource_id = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].id : azurerm_windows_function_app.main[0].id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "pdz-group-functions"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "functions" {
  count = var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${local.function_app_name}"
  target_resource_id         = var.os_type == "Linux" ? azurerm_linux_function_app.main[0].id : azurerm_windows_function_app.main[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "FunctionAppLogs"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}