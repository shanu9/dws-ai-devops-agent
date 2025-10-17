# =============================================================================
# HDINSIGHT MODULE VARIABLES
# =============================================================================

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

variable "resource_group_name" {
  type = string
}

variable "hdinsight_cluster_name" {
  type    = string
  default = null
}

variable "cluster_type" {
  description = "Cluster type (Hadoop, Spark, Kafka, HBase)"
  type        = string
  validation {
    condition     = contains(["Hadoop", "Spark", "Kafka", "HBase"], var.cluster_type)
    error_message = "Must be Hadoop, Spark, Kafka, or HBase."
  }
}

variable "cluster_version" {
  description = "HDInsight cluster version"
  type        = string
  default     = "5.1"
}

variable "cluster_tier" {
  description = "Cluster tier (Standard or Premium)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.cluster_tier)
    error_message = "Must be Standard or Premium."
  }
}

variable "hadoop_version" {
  type    = string
  default = "3.1"
}

variable "spark_version" {
  type    = string
  default = "3.3"
}

variable "kafka_version" {
  type    = string
  default = "2.4"
}

variable "hbase_version" {
  type    = string
  default = "2.4"
}

variable "gateway_username" {
  type    = string
  default = "admin"
}

variable "gateway_password" {
  type      = string
  default   = null
  sensitive = true
}

variable "ssh_username" {
  type    = string
  default = "sshuser"
}

variable "ssh_password" {
  type      = string
  default   = null
  sensitive = true
}

variable "head_node_vm_size" {
  type    = string
  default = "Standard_D3_V2"
}

variable "worker_node_vm_size" {
  type    = string
  default = "Standard_D3_V2"
}

variable "worker_node_count" {
  type    = number
  default = 3
}

variable "worker_node_disks_per_node" {
  description = "Number of disks per worker node (Kafka only)"
  type        = number
  default     = 2
}

variable "zookeeper_node_vm_size" {
  type    = string
  default = "Standard_A2_V2"
}

variable "vnet_id" {
  type    = string
  default = null
}

variable "subnet_id" {
  type    = string
  default = null
}

variable "key_vault_id" {
  description = "Key Vault ID to store passwords"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "cost_center" {
  type    = string
  default = "Big-Data"
}

variable "team" {
  type    = string
  default = "Data-Engineering"
}

variable "tags" {
  type    = map(string)
  default = {}
}