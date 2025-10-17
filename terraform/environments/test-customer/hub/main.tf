data "terraform_remote_state" "management" {
  backend = "azurerm"
  
  config = {
    resource_group_name  = var.state_resource_group
    storage_account_name = var.state_storage_account_name
    container_name       = var.state_container_name
    key                  = var.management_state_key
  }
}