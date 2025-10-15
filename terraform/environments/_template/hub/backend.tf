# Backend configuration for Terraform state
# State is stored in YOUR Azure Storage Account (secure, centralized)

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"           # Your state RG
    storage_account_name = "sttfstate${customer_id}"      # Per-customer state
    container_name       = "tfstate"
    key                  = "${customer_id}/hub.tfstate"
    
    # These are set via environment variables:
    # ARM_ACCESS_KEY or use managed identity
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
  
  # Customer's Azure subscription (set via env vars or service principal)
  # ARM_SUBSCRIPTION_ID
  # ARM_TENANT_ID
  # ARM_CLIENT_ID
  # ARM_CLIENT_SECRET
}