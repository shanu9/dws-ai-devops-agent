# =============================================================================
# STREAM ANALYTICS MODULE OUTPUTS
# =============================================================================

output "stream_analytics_job_id" {
  description = "Stream Analytics job ID"
  value       = azurerm_stream_analytics_job.main.id
}

output "stream_analytics_job_name" {
  description = "Stream Analytics job name"
  value       = azurerm_stream_analytics_job.main.name
}

output "job_identity" {
  description = "Stream Analytics job managed identity"
  value = {
    principal_id = azurerm_stream_analytics_job.main.identity[0].principal_id
    tenant_id    = azurerm_stream_analytics_job.main.identity[0].tenant_id
  }
}

output "input_names" {
  description = "List of input names"
  value = concat(
    [for k, v in azurerm_stream_analytics_stream_input_eventhub.inputs : v.name],
    [for k, v in azurerm_stream_analytics_stream_input_iothub.inputs : v.name],
    [for k, v in azurerm_stream_analytics_reference_input_blob.inputs : v.name]
  )
}

output "output_names" {
  description = "List of output names"
  value = concat(
    [for k, v in azurerm_stream_analytics_output_blob.outputs : v.name],
    [for k, v in azurerm_stream_analytics_output_eventhub.outputs : v.name],
    [for k, v in azurerm_stream_analytics_output_mssql.outputs : v.name],
    [for k, v in azurerm_stream_analytics_output_cosmosdb.outputs : v.name],
    [for k, v in azurerm_stream_analytics_output_powerbi.outputs : v.name]
  )
}