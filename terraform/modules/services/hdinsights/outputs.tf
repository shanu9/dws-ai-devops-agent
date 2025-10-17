# =============================================================================
# HDINSIGHT MODULE OUTPUTS
# =============================================================================

output "cluster_id" {
  value = var.cluster_type == "Hadoop" ? azurerm_hdinsight_hadoop_cluster.main[0].id : (
    var.cluster_type == "Spark" ? azurerm_hdinsight_spark_cluster.main[0].id : (
      var.cluster_type == "Kafka" ? azurerm_hdinsight_kafka_cluster.main[0].id : 
      azurerm_hdinsight_hbase_cluster.main[0].id
    )
  )
}

output "cluster_name" {
  value = local.hdinsight_cluster_name
}

output "https_endpoint" {
  value = var.cluster_type == "Hadoop" ? azurerm_hdinsight_hadoop_cluster.main[0].https_endpoint : (
    var.cluster_type == "Spark" ? azurerm_hdinsight_spark_cluster.main[0].https_endpoint : (
      var.cluster_type == "Kafka" ? azurerm_hdinsight_kafka_cluster.main[0].https_endpoint : 
      azurerm_hdinsight_hbase_cluster.main[0].https_endpoint
    )
  )
}

output "ssh_endpoint" {
  value = var.cluster_type == "Hadoop" ? azurerm_hdinsight_hadoop_cluster.main[0].ssh_endpoint : (
    var.cluster_type == "Spark" ? azurerm_hdinsight_spark_cluster.main[0].ssh_endpoint : (
      var.cluster_type == "Kafka" ? azurerm_hdinsight_kafka_cluster.main[0].ssh_endpoint : 
      azurerm_hdinsight_hbase_cluster.main[0].ssh_endpoint
    )
  )
}

output "storage_account_name" {
  value = azurerm_storage_account.hdinsight.name
}

output "gateway_password" {
  value     = var.gateway_password != null ? var.gateway_password : random_password.cluster_admin.result
  sensitive = true
}

output "ssh_password" {
  value     = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
  sensitive = true
}