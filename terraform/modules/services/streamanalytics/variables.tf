# =============================================================================
# STREAM ANALYTICS MODULE VARIABLES
# =============================================================================

variable "customer_id" {
  description = "Unique customer identifier"
  type        = string
}

variable "environment" {
  description = "Environment (dev/stg/prd)"
  type        = string
}

variable "spoke_name" {
  description = "Spoke name"
  type        = string
}

variable "region" {
  description = "Azure region"
  type        = string
}

variable "region_code" {
  description = "Short region code"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "stream_analytics_job_name" {
  description = "Stream Analytics job name (auto-generated if not provided)"
  type        = string
  default     = null
}

variable "compatibility_level" {
  description = "Compatibility level"
  type        = string
  default     = "1.2"
  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.compatibility_level)
    error_message = "Must be 1.0, 1.1, or 1.2."
  }
}

variable "data_locale" {
  description = "Data locale for parsing dates"
  type        = string
  default     = "en-US"
}

variable "events_late_arrival_max_delay" {
  description = "Max delay for late-arriving events (seconds)"
  type        = number
  default     = 5
}

variable "events_out_of_order_max_delay" {
  description = "Max delay for out-of-order events (seconds)"
  type        = number
  default     = 0
}

variable "events_out_of_order_policy" {
  description = "Policy for out-of-order events"
  type        = string
  default     = "Adjust"
  validation {
    condition     = contains(["Adjust", "Drop"], var.events_out_of_order_policy)
    error_message = "Must be Adjust or Drop."
  }
}

variable "output_error_policy" {
  description = "Policy for output errors"
  type        = string
  default     = "Drop"
  validation {
    condition     = contains(["Drop", "Stop"], var.output_error_policy)
    error_message = "Must be Drop or Stop."
  }
}

variable "streaming_units" {
  description = "Number of streaming units (1, 3, 6, 12, 18, 24, 30, 36, 42, 48)"
  type        = number
  default     = 3
  validation {
    condition     = contains([1, 3, 6, 12, 18, 24, 30, 36, 42, 48], var.streaming_units)
    error_message = "Must be valid SU count."
  }
}

variable "transformation_query" {
  description = "Stream Analytics query (SQL-like syntax)"
  type        = string
}

variable "job_storage_account_name" {
  description = "Storage account for custom code assemblies"
  type        = string
  default     = null
}

variable "job_storage_account_key" {
  description = "Storage account key"
  type        = string
  default     = null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# INPUTS
# -----------------------------------------------------------------------------

variable "eventhub_inputs" {
  description = "Event Hub inputs"
  type = map(object({
    eventhub_name        = string
    namespace_name       = string
    consumer_group_name  = string
    policy_name          = string
    policy_key           = string
    serialization_type   = string
    field_delimiter      = string
  }))
  default = {}
}

variable "iothub_inputs" {
  description = "IoT Hub inputs"
  type = map(object({
    iothub_name         = string
    endpoint            = string
    consumer_group_name = string
    policy_name         = string
    policy_key          = string
    serialization_type  = string
  }))
  default = {}
}

variable "blob_reference_inputs" {
  description = "Blob storage reference inputs"
  type = map(object({
    storage_account_name = string
    storage_account_key  = string
    container_name       = string
    path_pattern         = string
    date_format          = string
    time_format          = string
    serialization_type   = string
    field_delimiter      = string
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------

variable "blob_outputs" {
  description = "Blob storage outputs"
  type = map(object({
    storage_account_name = string
    storage_account_key  = string
    container_name       = string
    path_pattern         = string
    date_format          = string
    time_format          = string
    batch_max_wait_time  = string
    batch_min_rows       = number
    serialization_type   = string
    json_format          = string
    field_delimiter      = string
  }))
  default = {}
}

variable "eventhub_outputs" {
  description = "Event Hub outputs"
  type = map(object({
    eventhub_name      = string
    namespace_name     = string
    policy_name        = string
    policy_key         = string
    partition_key      = string
    property_columns   = list(string)
    serialization_type = string
  }))
  default = {}
}

variable "sql_outputs" {
  description = "SQL database outputs"
  type = map(object({
    server_name      = string
    database_name    = string
    table_name       = string
    username         = string
    password         = string
    max_batch_count  = number
    max_writer_count = number
  }))
  default = {}
}

variable "cosmosdb_outputs" {
  description = "Cosmos DB outputs"
  type = map(object({
    account_key   = string
    database_id   = string
    container_name = string
    document_id   = string
    partition_key = string
  }))
  default = {}
}

variable "powerbi_outputs" {
  description = "Power BI outputs"
  type = map(object({
    dataset_name = string
    table_name   = string
    group_id     = string
    group_name   = string
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "cost_center" {
  description = "Cost center"
  type        = string
  default     = "Real-Time-Analytics"
}

variable "team" {
  description = "Team"
  type        = string
  default     = "Data-Engineering"
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}