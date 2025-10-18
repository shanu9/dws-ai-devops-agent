terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate78a1dec0"
    container_name       = "tfstate"
    key                  = "spoke-production.tfstate"
    subscription_id      = "a177f15d-854f-4856-bba5-fd97bfbea053"  # ✅ CRITICAL: State is in Management subscription
  }
  
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
      configuration_aliases = [azurerm.hub]  # ✅ Required for hub provider
    }
  }
}

# ✅ DEFAULT PROVIDER - Deploys resources in Spoke subscription
provider "azurerm" {
  features {}
  subscription_id = "c3ef6837-804a-4136-aebf-552cdc17802f"
  skip_provider_registration = true
}

# ✅ HUB PROVIDER - For cross-subscription peering (Hub is in Management subscription)
provider "azurerm" {
  alias           = "hub"
  features {}
  subscription_id = "a177f15d-854f-4856-bba5-fd97bfbea053"
  skip_provider_registration = true
}