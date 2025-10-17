# Bootstrap Terraform State Storage
# Run this ONCE to create centralized state storage

$RESOURCE_GROUP = "rg-terraform-state"
$LOCATION = "eastus"
$RANDOM_SUFFIX = -join ((48..57) + (97..102) | Get-Random -Count 8 | ForEach-Object {[char]$_})
$STORAGE_ACCOUNT = "sttfstate$RANDOM_SUFFIX"
$CONTAINER_NAME = "tfstate"
$MGMT_SUB_ID = "a177f15d-854f-4856-bba5-fd97bfbea053"

Write-Host "Bootstrap Terraform State Storage..." -ForegroundColor Green

# Switch to Management subscription
az account set --subscription $MGMT_SUB_ID

# Create resource group
Write-Host "Creating resource group..." -ForegroundColor Yellow
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
Write-Host "Creating storage account: $STORAGE_ACCOUNT" -ForegroundColor Yellow
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_LRS --encryption-services blob --https-only true --min-tls-version TLS1_2 --allow-blob-public-access false

# Get storage key
$ACCOUNT_KEY = az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query "[0].value" -o tsv

# Create container
Write-Host "Creating container..." -ForegroundColor Yellow
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --account-key $ACCOUNT_KEY

# Enable versioning
az storage account blob-service-properties update --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --enable-versioning true

Write-Host ""
Write-Host "State storage ready!" -ForegroundColor Green
Write-Host "Storage Account: $STORAGE_ACCOUNT" -ForegroundColor Cyan
Write-Host ""
Write-Host "SAVE THIS - Update all backend.tf files with:" -ForegroundColor Yellow
Write-Host "storage_account_name = ""$STORAGE_ACCOUNT""" -ForegroundColor White

# Save to file
$STORAGE_ACCOUNT | Out-File -FilePath "storage-account-name.txt"
Write-Host ""
Write-Host "Storage account name saved to: storage-account-name.txt" -ForegroundColor Cyan