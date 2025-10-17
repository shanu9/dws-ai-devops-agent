# =============================================================================
# AZURE COSMOS DB MODULE
# =============================================================================
# Purpose: Globally distributed, multi-model NoSQL database
# Components: Cosmos account, databases, containers, private endpoints
# APIs: SQL, MongoDB, Cassandra, Gremlin, Table
# Best Practices: Geo-replication, consistency levels, cost optimization
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
  
  cosmos_account_name = coalesce(
    var.cosmos_account_name,
    "cosmos-${local.naming_prefix}"
  )
  
  # Remove hyphens for Cosmos (alphanumeric + hyphen, but must be lowercase)
  cosmos_account_name_clean = lower(replace(local.cosmos_account_name, "_", "-"))
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Cosmos-DB"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# RANDOM SUFFIX FOR UNIQUE NAMING
# -----------------------------------------------------------------------------

resource "random_string" "cosmos_suffix" {
  length  = 6
  special = false
  upper   = false
}

# -----------------------------------------------------------------------------
# COSMOS DB ACCOUNT
# -----------------------------------------------------------------------------

resource "azurerm_cosmosdb_account" "main" {
  name                = "${local.cosmos_account_name_clean}-${random_string.cosmos_suffix.result}"
  location            = var.region
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = var.cosmos_db_kind
  
  # Consistency Policy (Critical for distributed systems)
  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.consistency_level == "BoundedStaleness" ? var.max_staleness_interval : null
    max_staleness_prefix    = var.consistency_level == "BoundedStaleness" ? var.max_staleness_prefix : null
  }
  
  # Primary region
  geo_location {
    location          = var.region
    failover_priority = 0
    zone_redundant    = var.enable_zone_redundancy
  }
  
  # Additional regions (geo-replication)
  dynamic "geo_location" {
    for_each = var.failover_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.priority
      zone_redundant    = geo_location.value.zone_redundant
    }
  }
  
  # Capabilities (API-specific features)
  dynamic "capabilities" {
    for_each = var.capabilities
    content {
      name = capabilities.value
    }
  }
  
  # Backup Policy
  backup {
    type                = var.backup_type
    interval_in_minutes = var.backup_type == "Periodic" ? var.backup_interval_minutes : null
    retention_in_hours  = var.backup_type == "Periodic" ? var.backup_retention_hours : null
    storage_redundancy  = var.backup_type == "Periodic" ? var.backup_storage_redundancy : null
  }
  
  # Network Configuration
  public_network_access_enabled         = var.public_network_access_enabled
  is_virtual_network_filter_enabled     = var.enable_vnet_filter
  network_acl_bypass_for_azure_services = true
  
  # Virtual Network Rules
  dynamic "virtual_network_rule" {
    for_each = var.enable_vnet_filter && var.subnet_id != null ? [1] : []
    content {
      id                                   = var.subnet_id
      ignore_missing_vnet_service_endpoint = false
    }
  }
  
  # IP Firewall Rules
  ip_range_filter = var.public_network_access_enabled ? join(",", var.ip_range_filter) : ""
  
  # Analytical Storage (for synapse link)
  analytical_storage_enabled = var.enable_analytical_storage
  
  # Free tier (one per subscription - for dev/test)
  enable_free_tier = var.enable_free_tier
  
  # Automatic failover
  enable_automatic_failover = var.enable_automatic_failover
  
  # Multi-region writes (expensive but powerful)
  enable_multiple_write_locations = var.enable_multiple_write_locations
  
  # Identity
  identity {
    type = "SystemAssigned"
  }
  
  tags = local.common_tags
  
  lifecycle {
    ignore_changes = [
      # Prevent destruction of data
      backup
    ]
  }
}

# -----------------------------------------------------------------------------
# SQL API DATABASES (if using SQL API)
# -----------------------------------------------------------------------------

resource "azurerm_cosmosdb_sql_database" "main" {
  for_each = var.cosmos_db_kind == "GlobalDocumentDB" ? var.sql_databases : {}
  
  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  
  # Throughput configuration
  throughput = each.value.autoscale_enabled ? null : each.value.throughput
  
  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_enabled ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "main" {
  for_each = var.cosmos_db_kind == "GlobalDocumentDB" ? var.sql_containers : {}
  
  name                = each.value.container_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main[each.value.database_name].name
  partition_key_path  = each.value.partition_key_path
  
  # Throughput
  throughput = each.value.autoscale_enabled ? null : each.value.throughput
  
  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_enabled ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }
  
  # Indexing Policy
  indexing_policy {
    indexing_mode = each.value.indexing_mode
    
    dynamic "included_path" {
      for_each = each.value.included_paths
      content {
        path = included_path.value
      }
    }
    
    dynamic "excluded_path" {
      for_each = each.value.excluded_paths
      content {
        path = excluded_path.value
      }
    }
  }
  
  # TTL
  default_ttl = each.value.default_ttl
  
  # Analytical Storage TTL (for Synapse Link)
  analytical_storage_ttl = var.enable_analytical_storage ? each.value.analytical_storage_ttl : null
  
  # Unique Keys
  dynamic "unique_key" {
    for_each = each.value.unique_keys
    content {
      paths = unique_key.value
    }
  }
}

# -----------------------------------------------------------------------------
# MONGODB API DATABASES (if using MongoDB)
# -----------------------------------------------------------------------------

resource "azurerm_cosmosdb_mongo_database" "main" {
  for_each = var.cosmos_db_kind == "MongoDB" ? var.mongo_databases : {}
  
  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  
  throughput = each.value.autoscale_enabled ? null : each.value.throughput
  
  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_enabled ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }
}

resource "azurerm_cosmosdb_mongo_collection" "main" {
  for_each = var.cosmos_db_kind == "MongoDB" ? var.mongo_collections : {}
  
  name                = each.value.collection_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_mongo_database.main[each.value.database_name].name
  
  shard_key = each.value.shard_key
  
  throughput = each.value.autoscale_enabled ? null : each.value.throughput
  
  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_enabled ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }
  
  # Indexes
  dynamic "index" {
    for_each = each.value.indexes
    content {
      keys   = index.value.keys
      unique = index.value.unique
    }
  }
  
  default_ttl_seconds = each.value.default_ttl
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINTS
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "cosmos" {
  count = var.enable_private_endpoint ? 1 : 0
  
  name                = "pe-${local.cosmos_account_name_clean}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  
  private_service_connection {
    name                           = "psc-${local.cosmos_account_name_clean}"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    is_manual_connection           = false
    subresource_names              = [var.private_endpoint_subresource]
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "pdz-group-cosmos"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  count = var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${local.cosmos_account_name_clean}"
  target_resource_id         = azurerm_cosmosdb_account.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "DataPlaneRequests"
  }
  
  enabled_log {
    category = "MongoRequests"
  }
  
  enabled_log {
    category = "QueryRuntimeStatistics"
  }
  
  enabled_log {
    category = "PartitionKeyStatistics"
  }
  
  enabled_log {
    category = "ControlPlaneRequests"
  }
  
  metric {
    category = "Requests"
    enabled  = true
  }
}