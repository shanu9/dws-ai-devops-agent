# =============================================================================
# AZURE MACHINE LEARNING MODULE
# =============================================================================
# Purpose: Enterprise ML workspace with compute clusters and model registry
# Components: ML workspace, compute instances, clusters, datastores
# Best Practices: Private endpoints, managed identity, cost optimization
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

# -----------------------------------------------------------------------------
# LOCAL VARIABLES
# -----------------------------------------------------------------------------

locals {
  naming_prefix = "${var.customer_id}-${var.spoke_name}-${var.region_code}"
  
  ml_workspace_name = coalesce(
    var.ml_workspace_name,
    "mlw-${local.naming_prefix}"
  )
  
  storage_account_name   = "mlstorage${replace(local.naming_prefix, "-", "")}${random_string.storage_suffix.result}"
  key_vault_name         = "mlkv-${local.naming_prefix}-${random_string.kv_suffix.result}"
  app_insights_name      = "mlai-${local.naming_prefix}"
  container_registry_name = "mlcr${replace(local.naming_prefix, "-", "")}${random_string.acr_suffix.result}"
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Machine-Learning"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# RANDOM SUFFIXES FOR UNIQUE NAMING
# -----------------------------------------------------------------------------

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "random_string" "acr_suffix" {
  length  = 6
  special = false
  upper   = false
}

# -----------------------------------------------------------------------------
# STORAGE ACCOUNT (Required for ML Workspace)
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "ml" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type
  account_kind             = "StorageV2"
  
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  # Network rules
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# KEY VAULT (Required for ML Workspace)
# -----------------------------------------------------------------------------

resource "azurerm_key_vault" "ml" {
  name                       = local.key_vault_name
  location                   = var.region
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.enable_purge_protection
  
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# APPLICATION INSIGHTS (Required for ML Workspace)
# -----------------------------------------------------------------------------

resource "azurerm_application_insights" "ml" {
  name                = local.app_insights_name
  location            = var.region
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = var.log_analytics_workspace_id
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# CONTAINER REGISTRY (Required for custom environments)
# -----------------------------------------------------------------------------

resource "azurerm_container_registry" "ml" {
  count = var.enable_container_registry ? 1 : 0
  
  name                = local.container_registry_name
  resource_group_name = var.resource_group_name
  location            = var.region
  sku                 = var.container_registry_sku
  admin_enabled       = false
  
  # Network rules
  public_network_access_enabled = var.public_network_access_enabled
  network_rule_bypass_option    = "AzureServices"
  
  dynamic "network_rule_set" {
    for_each = var.public_network_access_enabled ? [] : [1]
    content {
      default_action = "Deny"
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# MACHINE LEARNING WORKSPACE
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "azurerm_machine_learning_workspace" "main" {
  name                    = local.ml_workspace_name
  location                = var.region
  resource_group_name     = var.resource_group_name
  application_insights_id = azurerm_application_insights.ml.id
  key_vault_id            = azurerm_key_vault.ml.id
  storage_account_id      = azurerm_storage_account.ml.id
  container_registry_id   = var.enable_container_registry ? azurerm_container_registry.ml[0].id : null
  
  # Identity
  identity {
    type = "SystemAssigned"
  }
  
  # Network isolation
  public_network_access_enabled = var.public_network_access_enabled
  
  # High Business Impact (HBI) workspace
  high_business_impact = var.enable_hbi_workspace
  
  # Encryption
  dynamic "encryption" {
    for_each = var.customer_managed_key_id != null ? [1] : []
    content {
      key_vault_id = var.customer_managed_key_id
      key_id       = var.customer_managed_key_id
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# COMPUTE CLUSTER (For training)
# -----------------------------------------------------------------------------

resource "azurerm_machine_learning_compute_cluster" "main" {
  for_each = var.compute_clusters
  
  name                          = each.key
  machine_learning_workspace_id = azurerm_machine_learning_workspace.main.id
  location                      = var.region
  vm_priority                   = each.value.vm_priority
  vm_size                       = each.value.vm_size
  
  # Scale settings (Cost optimization)
  scale_settings {
    min_node_count                       = each.value.min_nodes
    max_node_count                       = each.value.max_nodes
    scale_down_nodes_after_idle_duration = each.value.idle_seconds_before_scaledown
  }
  
  # Identity
  identity {
    type = "SystemAssigned"
  }
  
  # Network settings
  dynamic "subnet_resource_id" {
    for_each = each.value.subnet_id != null ? [1] : []
    content {
      subnet_resource_id = each.value.subnet_id
    }
  }
  
  # SSH access (optional - for debugging)
  dynamic "ssh" {
    for_each = each.value.enable_ssh ? [1] : []
    content {
      admin_username = each.value.ssh_admin_username
      admin_password = each.value.ssh_admin_password
    }
  }
  
  description = each.value.description
  tags        = local.common_tags
}

# -----------------------------------------------------------------------------
# COMPUTE INSTANCE (For development)
# -----------------------------------------------------------------------------

resource "azurerm_machine_learning_compute_instance" "main" {
  for_each = var.compute_instances
  
  name                          = each.key
  machine_learning_workspace_id = azurerm_machine_learning_workspace.main.id
  location                      = var.region
  virtual_machine_size          = each.value.vm_size
  
  # Auto-shutdown (Cost optimization)
  dynamic "assign_to_user" {
    for_each = each.value.assigned_user_object_id != null ? [1] : []
    content {
      object_id = each.value.assigned_user_object_id
      tenant_id = data.azurerm_client_config.current.tenant_id
    }
  }
  
  # SSH access
  dynamic "ssh" {
    for_each = each.value.enable_ssh ? [1] : []
    content {
      public_key = each.value.ssh_public_key
    }
  }
  
  # Subnet
  subnet_resource_id = each.value.subnet_id
  
  description = each.value.description
  tags        = local.common_tags
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINTS
# -----------------------------------------------------------------------------

# Private endpoint for ML Workspace
resource "azurerm_private_endpoint" "ml_workspace" {
  count = var.enable_private_endpoint ? 1 : 0
  
  name                = "pe-${local.ml_workspace_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.ml_workspace_name}"
    private_connection_resource_id = azurerm_machine_learning_workspace.main.id
    is_manual_connection           = false
    subresource_names              = ["amlworkspace"]
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id_ml != null ? [1] : []
    content {
      name                 = "pdz-group-ml"
      private_dns_zone_ids = [var.private_dns_zone_id_ml]
    }
  }
  
  tags = local.common_tags
}

# Private endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  count = var.enable_private_endpoint ? 1 : 0
  
  name                = "pe-${local.storage_account_name}-blob"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.storage_account_name}-blob"
    private_connection_resource_id = azurerm_storage_account.ml.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id_storage != null ? [1] : []
    content {
      name                 = "pdz-group-storage"
      private_dns_zone_ids = [var.private_dns_zone_id_storage]
    }
  }
  
  tags = local.common_tags
}

# Private endpoint for Container Registry
resource "azurerm_private_endpoint" "acr" {
  count = var.enable_container_registry && var.enable_private_endpoint ? 1 : 0
  
  name                = "pe-${local.container_registry_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.container_registry_name}"
    private_connection_resource_id = azurerm_container_registry.ml[0].id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id_acr != null ? [1] : []
    content {
      name                 = "pdz-group-acr"
      private_dns_zone_ids = [var.private_dns_zone_id_acr]
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# RBAC: Grant ML workspace access to Key Vault
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_access_policy" "ml_workspace" {
  key_vault_id = azurerm_key_vault.ml.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_machine_learning_workspace.main.identity[0].principal_id
  
  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]
  
  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "WrapKey",
    "UnwrapKey"
  ]
}

# Grant ML workspace access to Storage
resource "azurerm_role_assignment" "ml_storage" {
  scope                = azurerm_storage_account.ml.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_machine_learning_workspace.main.identity[0].principal_id
}

# Grant ML workspace access to Container Registry
resource "azurerm_role_assignment" "ml_acr" {
  count = var.enable_container_registry ? 1 : 0
  
  scope                = azurerm_container_registry.ml[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_machine_learning_workspace.main.identity[0].principal_id
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "ml_workspace" {
  count = var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${local.ml_workspace_name}"
  target_resource_id         = azurerm_machine_learning_workspace.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "AmlComputeClusterEvent"
  }
  
  enabled_log {
    category = "AmlComputeClusterNodeEvent"
  }
  
  enabled_log {
    category = "AmlComputeJobEvent"
  }
  
  enabled_log {
    category = "AmlRunStatusChangedEvent"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}