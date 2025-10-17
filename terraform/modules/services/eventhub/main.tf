# =============================================================================
# AZURE EVENT HUB MODULE
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
  eventhub_namespace_name = coalesce(
    var.eventhub_namespace_name,
    "evhns-${local.naming_prefix}"
  )
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Event-Hub"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# EVENT HUB NAMESPACE
# -----------------------------------------------------------------------------

resource "azurerm_eventhub_namespace" "main" {
  name                = local.eventhub_namespace_name
  location            = var.region
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  capacity            = var.capacity
  
  # Auto-inflate (Standard and higher)
  auto_inflate_enabled     = var.sku != "Basic" ? var.enable_auto_inflate : false
  maximum_throughput_units = var.sku != "Basic" && var.enable_auto_inflate ? var.maximum_throughput_units : null
  
  # Zone redundancy (Premium only)
  zone_redundant = var.sku == "Premium" ? var.enable_zone_redundancy : false
  
  # Kafka enabled
  kafka_enabled = var.enable_kafka
  
  # Network rules
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version          = "1.2"
  
  dynamic "network_rulesets" {
    for_each = var.public_network_access_enabled ? [1] : []
    content {
      default_action                 = "Deny"
      trusted_service_access_enabled = true
      
      dynamic "ip_rule" {
        for_each = var.allowed_ip_ranges
        content {
          ip_mask = ip_rule.value
        }
      }
      
      dynamic "virtual_network_rule" {
        for_each = var.allowed_subnet_ids
        content {
          subnet_id = virtual_network_rule.value
        }
      }
    }
  }
  
  # Identity
  identity {
    type = "SystemAssigned"
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# EVENT HUBS
# -----------------------------------------------------------------------------

resource "azurerm_eventhub" "hubs" {
  for_each = var.event_hubs
  
  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  partition_count     = each.value.partition_count
  message_retention   = each.value.message_retention_days
  
  # Capture to storage (optional)
  dynamic "capture_description" {
    for_each = each.value.enable_capture ? [1] : []
    content {
      enabled             = true
      encoding            = each.value.capture_encoding
      interval_in_seconds = each.value.capture_interval_seconds
      size_limit_in_bytes = each.value.capture_size_limit_bytes
      skip_empty_archives = each.value.capture_skip_empty_archives
      
      destination {
        name                = "EventHubArchive.AzureBlockBlob"
        archive_name_format = each.value.capture_name_format
        blob_container_name = each.value.capture_container_name
        storage_account_id  = each.value.capture_storage_account_id
      }
    }
  }
}

# -----------------------------------------------------------------------------
# CONSUMER GROUPS
# -----------------------------------------------------------------------------

resource "azurerm_eventhub_consumer_group" "groups" {
  for_each = var.consumer_groups
  
  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.hubs[each.value.eventhub_name].name
  resource_group_name = var.resource_group_name
  user_metadata       = each.value.user_metadata
}

# -----------------------------------------------------------------------------
# AUTHORIZATION RULES
# -----------------------------------------------------------------------------

resource "azurerm_eventhub_namespace_authorization_rule" "rules" {
  for_each = var.namespace_authorization_rules
  
  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  listen              = each.value.listen
  send                = each.value.send
  manage              = each.value.manage
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "eventhub" {
  count = var.enable_private_endpoint ? 1 : 0
  
  name                = "pe-${local.eventhub_namespace_name}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.eventhub_namespace_name}"
    private_connection_resource_id = azurerm_eventhub_namespace.main.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "pdz-group-eventhub"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "eventhub" {
  count = var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${local.eventhub_namespace_name}"
  target_resource_id         = azurerm_eventhub_namespace.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "ArchiveLogs"
  }
  
  enabled_log {
    category = "OperationalLogs"
  }
  
  enabled_log {
    category = "AutoScaleLogs"
  }
  
  enabled_log {
    category = "KafkaCoordinatorLogs"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}