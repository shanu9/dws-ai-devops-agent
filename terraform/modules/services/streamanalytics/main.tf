# =============================================================================
# AZURE STREAM ANALYTICS MODULE
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
  stream_analytics_job_name = coalesce(
    var.stream_analytics_job_name,
    "asa-${local.naming_prefix}"
  )
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "Stream-Analytics"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

# -----------------------------------------------------------------------------
# STREAM ANALYTICS JOB
# -----------------------------------------------------------------------------

resource "azurerm_stream_analytics_job" "main" {
  name                                     = local.stream_analytics_job_name
  resource_group_name                      = var.resource_group_name
  location                                 = var.region
  compatibility_level                      = var.compatibility_level
  data_locale                              = var.data_locale
  events_late_arrival_max_delay_in_seconds = var.events_late_arrival_max_delay
  events_out_of_order_max_delay_in_seconds = var.events_out_of_order_max_delay
  events_out_of_order_policy               = var.events_out_of_order_policy
  output_error_policy                      = var.output_error_policy
  streaming_units                          = var.streaming_units
  
  # Transformation query
  transformation_query = var.transformation_query
  
  # Job storage account (for custom code assemblies)
  dynamic "job_storage_account" {
    for_each = var.job_storage_account_name != null ? [1] : []
    content {
      account_name = var.job_storage_account_name
      account_key  = var.job_storage_account_key
    }
  }
  
  # Identity
  identity {
    type = "SystemAssigned"
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# EVENT HUB INPUT
# -----------------------------------------------------------------------------

resource "azurerm_stream_analytics_stream_input_eventhub" "inputs" {
  for_each = var.eventhub_inputs
  
  name                         = each.key
  stream_analytics_job_name    = azurerm_stream_analytics_job.main.name
  resource_group_name          = var.resource_group_name
  eventhub_consumer_group_name = each.value.consumer_group_name
  eventhub_name                = each.value.eventhub_name
  servicebus_namespace         = each.value.namespace_name
  shared_access_policy_key     = each.value.policy_key
  shared_access_policy_name    = each.value.policy_name
  
  serialization {
    type     = each.value.serialization_type
    encoding = each.value.serialization_type != "Avro" ? "UTF8" : null
    
    dynamic "field_delimiter" {
      for_each = each.value.serialization_type == "Csv" ? [1] : []
      content {
        field_delimiter = each.value.field_delimiter
      }
    }
  }
}

# -----------------------------------------------------------------------------
# IOT HUB INPUT
# -----------------------------------------------------------------------------

resource "azurerm_stream_analytics_stream_input_iothub" "inputs" {
  for_each = var.iothub_inputs
  
  name                      = each.key
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  endpoint                  = each.value.endpoint
  iothub_namespace          = each.value.iothub_name
  eventhub_consumer_group_name = each.value.consumer_group_name
  shared_access_policy_key  = each.value.policy_key
  shared_access_policy_name = each.value.policy_name
  
  serialization {
    type     = each.value.serialization_type
    encoding = "UTF8"
  }
}

# -----------------------------------------------------------------------------
# BLOB STORAGE INPUT (Reference Data)
# -----------------------------------------------------------------------------

resource "azurerm_stream_analytics_reference_input_blob" "inputs" {
  for_each = var.blob_reference_inputs
  
  name                      = each.key
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  storage_account_name      = each.value.storage_account_name
  storage_account_key       = each.value.storage_account_key
  storage_container_name    = each.value.container_name
  path_pattern              = each.value.path_pattern
  date_format               = each.value.date_format
  time_format               = each.value.time_format
  
  serialization {
    type     = each.value.serialization_type
    encoding = "UTF8"
    
    dynamic "field_delimiter" {
      for_each = each.value.serialization_type == "Csv" ? [1] : []
      content {
        field_delimiter = each.value.field_delimiter
      }
    }
  }
}

# -----------------------------------------------------------------------------
# BLOB STORAGE OUTPUT
# -----------------------------------------------------------------------------

resource "azurerm_stream_analytics_output_blob" "outputs" {
  for_each = var.blob_outputs
  
  name                      = each.key
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  storage_account_name      = each.value.storage_account_name
  storage_account_key       = each.value.storage_account_key
  storage_container_name    = each.value.container_name
  path_pattern              = each.value.path_pattern
  date_format               = each.value.date_format
  time_format               = each.value.time_format
  batch_max_wait_time       = each.value.batch_max_wait_time
  batch_min_rows            = each.value.batch_min_rows
  
  serialization {
    type     = each.value.serialization_type
    encoding = "UTF8"
    format   = each.value.serialization_type == "Json" ? each.value.json_format : null
    
    dynamic "field_delimiter" {
      for_each = each.value.serialization_type == "Csv" ? [1] : []
      content {
        field_delimiter = each.value.field_delimiter
      }
    }
  }
}

# -----------------------------------------------------------------------------
# EVENT HUB OUTPUT
# -----------------------------------------------------------------------------

resource "azurerm_stream_analytics_output_eventhub" "outputs" {
  for_each = var.eventhub_outputs
  
  name                         = each.key
  stream_analytics_job_name    = azurerm_stream_analytics_job.main.name
  resource_group_name          = var.resource_group_name
  eventhub_name                = each.value.eventhub_name
  servicebus_namespace         = each.value.namespace_name
  shared_access_policy_key     = each.value.policy_key
  shared_access_policy_name    = each.value.policy_name
  partition_key                = each.value.partition_key
  property_columns             = each.value.property_columns
  
  serialization {
    type     = each.value.serialization_type
    encoding = "UTF8"
    format   = each.value.serialization_type == "Json" ? "Array" : null
  }
}

# -----------------------------------------------------------------------------
# SQL DATABASE OUTPUT
# -----------------------------------------------------------------------------

resource "azurerm_stream_analytics_output_mssql" "outputs" {
  for_each = var.sql_outputs
  
  name                      = each.key
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  server                    = each.value.server_name
  database                  = each.value.database_name
  table                     = each.value.table_name
  user                      = each.value.username
  password                  = each.value.password
  max_batch_count           = each.value.max_batch_count
  max_writer_count          = each.value.max_writer_count
}

# -----------------------------------------------------------------------------
# COSMOS DB OUTPUT
# -----------------------------------------------------------------------------

resource "azurerm_stream_analytics_output_cosmosdb" "outputs" {
  for_each = var.cosmosdb_outputs
  
  name                      = each.key
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  cosmosdb_account_key      = each.value.account_key
  cosmosdb_sql_database_id  = each.value.database_id
  container_name            = each.value.container_name
  document_id               = each.value.document_id
  partition_key             = each.value.partition_key
}

# -----------------------------------------------------------------------------
# POWER BI OUTPUT
# -----------------------------------------------------------------------------

resource "azurerm_stream_analytics_output_powerbi" "outputs" {
  for_each = var.powerbi_outputs
  
  name                      = each.key
  stream_analytics_job_name = azurerm_stream_analytics_job.main.name
  resource_group_name       = var.resource_group_name
  dataset                   = each.value.dataset_name
  table                     = each.value.table_name
  group_id                  = each.value.group_id
  group_name                = each.value.group_name
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "stream_analytics" {
  count = var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${local.stream_analytics_job_name}"
  target_resource_id         = azurerm_stream_analytics_job.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "Execution"
  }
  
  enabled_log {
    category = "Authoring"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}