#!/bin/bash
# File: scripts/bootstrap-terraform-state.sh

# Variables
RESOURCE_GROUP="rg-terraform-state"
LOCATION="eastus"
STORAGE_ACCOUNT="sttfstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
MGMT_SUB_ID="a177f15d-854f-4856-bba5-fd97bfbea053"

echo "🚀 Bootstrapping Terraform State Storage..."

# Set subscription
az account set --subscription $MGMT_SUB_ID

# Create resource group
echo "Creating resource group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create storage account
echo "Creating storage account: $STORAGE_ACCOUNT"
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Get storage key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' -o tsv)

# Create container
echo "Creating container..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY

# Enable versioning
az storage account blob-service-properties update \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --enable-versioning true

echo "✅ State storage ready!"
echo "Storage Account: $STORAGE_ACCOUNT"
echo ""
echo "📝 Update backend.tf files with:"
echo "storage_account_name = \"$STORAGE_ACCOUNT\""