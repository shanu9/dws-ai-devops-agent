terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate78a1dec0"
    container_name       = "tfstate"
    key                  = "hub.tfstate"
    subscription_id      = "a177f15d-854f-4856-bba5-fd97bfbea053"  # ✅ CRITICAL: State is in Management subscription
  }
  
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
  subscription_id = "a177f15d-854f-4856-bba5-fd97bfbea053" 
}