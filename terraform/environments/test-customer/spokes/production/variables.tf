# =============================================================================
# SPOKE VARIABLES
# =============================================================================

# -----------------------------------------------------------------------------
# IDENTITY
# -----------------------------------------------------------------------------

variable "customer_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "spoke_name" {
  type = string
}

variable "region" {
  type = string
}

variable "region_code" {
  type = string
}

# -----------------------------------------------------------------------------
# NETWORK
# -----------------------------------------------------------------------------

variable "spoke_vnet_cidr" {
  type = string
}

# -----------------------------------------------------------------------------
# COST ALLOCATION
# -----------------------------------------------------------------------------

variable "cost_center" {
  type    = string
  default = "Production-Workloads"
}

variable "team" {
  type    = string
  default = "Platform-Team"
}

variable "tags" {
  type = map(string)
  default = {
    Workload   = "Production"
    DeployedBy = "Terraform"
  }
}

# =============================================================================
# SERVICE TOGGLES
# =============================================================================

variable "enable_sql" {
  type    = bool
  default = false
}

variable "enable_keyvault" {
  type    = bool
  default = false
}

variable "enable_storage" {
  type    = bool
  default = false
}

variable "enable_datafactory" {
  type    = bool
  default = false
}

variable "enable_synapse" {
  type    = bool
  default = false
}

variable "enable_cosmosdb" {
  type    = bool
  default = false
}

variable "enable_ml" {
  type    = bool
  default = false
}

variable "enable_cognitive_search" {
  type    = bool
  default = false
}

variable "enable_functions" {
  type    = bool
  default = false
}

variable "enable_eventhub" {
  type    = bool
  default = false
}

variable "enable_stream_analytics" {
  type    = bool
  default = false
}

variable "enable_purview" {
  type    = bool
  default = false
}

# =============================================================================
# SQL DATABASE CONFIGURATION
# =============================================================================

variable "sql_database_name" {
  type    = string
  default = "app-db"
}

variable "sql_admin_username" {
  type    = string
  default = "sqladmin"
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
  default   = null
}

variable "sql_sku_name" {
  type    = string
  default = "GP_S_Gen5_2"
}

variable "sql_min_capacity" {
  type    = number
  default = 0.5
}

variable "sql_auto_pause_delay" {
  type    = number
  default = 60
}

# =============================================================================
# KEY VAULT CONFIGURATION
# =============================================================================

variable "keyvault_purge_protection" {
  type    = bool
  default = true
}

# =============================================================================
# STORAGE CONFIGURATION
# =============================================================================

variable "storage_enable_data_lake" {
  type    = bool
  default = true
}

variable "storage_replication_type" {
  type    = string
  default = "GRS"
}

# =============================================================================
# SYNAPSE CONFIGURATION
# =============================================================================

variable "synapse_sql_admin_username" {
  type    = string
  default = "sqladmin"
}

variable "synapse_sql_admin_password" {
  type      = string
  sensitive = true
  default   = null
}

variable "synapse_enable_sql_pool" {
  type    = bool
  default = false
}

variable "synapse_enable_spark_pool" {
  type    = bool
  default = true
}

variable "synapse_spark_node_size" {
  type    = string
  default = "Small"
}

variable "synapse_spark_node_count_min" {
  type    = number
  default = 3
}

variable "synapse_spark_node_count_max" {
  type    = number
  default = 10
}

# =============================================================================
# COSMOS DB CONFIGURATION
# =============================================================================

variable "cosmosdb_kind" {
  type    = string
  default = "GlobalDocumentDB"
}

variable "cosmosdb_consistency_level" {
  type    = string
  default = "Session"
}

variable "cosmosdb_sql_databases" {
  type = map(object({
    throughput        = number
    autoscale_enabled = bool
    max_throughput    = number
  }))
  default = {}
}

variable "cosmosdb_sql_containers" {
  type = map(object({
    database_name           = string
    container_name          = string
    partition_key_path      = string
    throughput              = number
    autoscale_enabled       = bool
    max_throughput          = number
    indexing_mode           = string
    included_paths          = list(string)
    excluded_paths          = list(string)
    default_ttl             = number
    analytical_storage_ttl  = number
    unique_keys             = list(list(string))
  }))
  default = {}
}

# =============================================================================
# AZURE ML CONFIGURATION
# =============================================================================

variable "ml_enable_hbi" {
  type    = bool
  default = false
}

variable "ml_enable_acr" {
  type    = bool
  default = true
}

variable "ml_compute_clusters" {
  type = map(object({
    vm_size                        = string
    vm_priority                    = string
    min_nodes                      = number
    max_nodes                      = number
    idle_seconds_before_scaledown  = string
    subnet_id                      = string
    enable_ssh                     = bool
    ssh_admin_username             = string
    ssh_admin_password             = string
    description                    = string
  }))
  default = {}
}

# =============================================================================
# COGNITIVE SEARCH CONFIGURATION
# =============================================================================

variable "cognitive_search_sku" {
  type    = string
  default = "standard"
}

variable "cognitive_search_replica_count" {
  type    = number
  default = 1
}

variable "cognitive_search_partition_count" {
  type    = number
  default = 1
}

# =============================================================================
# FUNCTIONS CONFIGURATION
# =============================================================================

variable "functions_os_type" {
  type    = string
  default = "Linux"
}

variable "functions_plan_type" {
  type    = string
  default = "Consumption"
}

variable "functions_runtime" {
  type    = string
  default = "node"
}

# =============================================================================
# EVENT HUB CONFIGURATION
# =============================================================================

variable "eventhub_sku" {
  type    = string
  default = "Standard"
}

variable "eventhub_capacity" {
  type    = number
  default = 1
}

variable "eventhub_hubs" {
  type = map(object({
    partition_count                = number
    message_retention_days         = number
    enable_capture                 = bool
    capture_encoding               = string
    capture_interval_seconds       = number
    capture_size_limit_bytes       = number
    capture_skip_empty_archives    = bool
    capture_name_format            = string
    capture_container_name         = string
    capture_storage_account_id     = string
  }))
  default = {}
}

variable "eventhub_consumer_groups" {
  type = map(object({
    eventhub_name = string
    user_metadata = string
  }))
  default = {}
}

# =============================================================================
# STREAM ANALYTICS CONFIGURATION
# =============================================================================

variable "stream_analytics_streaming_units" {
  type    = number
  default = 3
}

variable "stream_analytics_query" {
  type    = string
  default = "SELECT * INTO [output] FROM [input]"
}

variable "stream_analytics_eventhub_inputs" {
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

variable "stream_analytics_blob_outputs" {
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

# =============================================================================
# PURVIEW CONFIGURATION
# =============================================================================

variable "purview_storage_account_ids" {
  type    = list(string)
  default = []
}

variable "purview_sql_server_ids" {
  type    = list(string)
  default = []
}