# =============================================================================
# SETUP CUSTOMER - Onboard New Customer
# =============================================================================
# Usage: .\setup-customer.ps1 -CustomerId "contoso" -Region "eastus"

param(
    [Parameter(Mandatory=$true)]
    [string]$CustomerId,
    
    [Parameter(Mandatory=$true)]
    [string]$Region,
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "prd",
    
    [Parameter(Mandatory=$false)]
    [string]$StateStorageAccount = "sttfstate",
    
    [Parameter(Mandatory=$false)]
    [string]$StateResourceGroup = "rg-terraform-state"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Customer Onboarding: $CustomerId" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------
# Step 1: Validate Customer ID
# -----------------------------------------------------------------------------

Write-Host "`n[1/6] Validating customer ID..." -ForegroundColor Yellow

if ($CustomerId -notmatch "^[a-z0-9]{3,6}$") {
    Write-Error "Customer ID must be 3-6 lowercase alphanumeric characters"
}

Write-Host "✓ Customer ID valid: $CustomerId" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Step 2: Create Customer Directory Structure
# -----------------------------------------------------------------------------

Write-Host "`n[2/6] Creating customer directory structure..." -ForegroundColor Yellow

$customerDir = "customers\$CustomerId"

$directories = @(
    "$customerDir",
    "terraform\environments\$CustomerId",
    "terraform\environments\$CustomerId\hub",
    "terraform\environments\$CustomerId\management",
    "terraform\environments\$CustomerId\spokes\production"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Gray
    }
}

Write-Host "✓ Directory structure created" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Step 3: Copy Template Files
# -----------------------------------------------------------------------------

Write-Host "`n[3/6] Copying template files..." -ForegroundColor Yellow

# Copy Hub template
Copy-Item -Path "terraform\environments\_template\hub\*" -Destination "terraform\environments\$CustomerId\hub\" -Force

# Copy Management template
Copy-Item -Path "terraform\environments\_template\management\*" -Destination "terraform\environments\$CustomerId\management\" -Force

# Copy Spoke template
Copy-Item -Path "terraform\environments\_template\spokes\production\*" -Destination "terraform\environments\$CustomerId\spokes\production\" -Force

Write-Host "✓ Template files copied" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Step 4: Create Customer Configuration File
# -----------------------------------------------------------------------------

Write-Host "`n[4/6] Creating customer configuration..." -ForegroundColor Yellow

$regionCode = switch -Regex ($Region) {
    "eastus"  { "eus" }
    "westus"  { "wus" }
    "japaneast" { "jpe" }
    "japanwest" { "jpw" }
    default   { "eus" }
}

$customerConfig = @"
# Customer: $CustomerId
# Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

customer_id: $CustomerId
environment: $Environment
region: $Region
region_code: $regionCode

# Subscriptions (to be filled by customer)
hub_subscription_id: ""
management_subscription_id: ""
spoke_subscription_ids:
  production: ""
  
# Service Principal (for deployments)
service_principal:
  tenant_id: ""
  client_id: ""
  client_secret: ""  # Store in Azure Key Vault

# Contact
primary_contact: ""
email: ""
phone: ""

# Cost Center
cost_center: "$CustomerId-Production"
monthly_budget: 0

# Deployment status
status: created
created_date: $(Get-Date -Format "yyyy-MM-dd")
"@

$customerConfig | Out-File -FilePath "$customerDir\config.yaml" -Encoding UTF8

Write-Host "✓ Customer config created: $customerDir\config.yaml" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Step 5: Create Terraform State Storage
# -----------------------------------------------------------------------------

Write-Host "`n[5/6] Setting up Terraform state storage..." -ForegroundColor Yellow

# Check if state storage exists
$stateAccountName = "${StateStorageAccount}${CustomerId}"

try {
    az storage account show --name $stateAccountName --resource-group $StateResourceGroup 2>&1 | Out-Null
    Write-Host "  State storage already exists: $stateAccountName" -ForegroundColor Gray
} catch {
    Write-Host "  Creating state storage account: $stateAccountName" -ForegroundColor Gray
    
    az storage account create `
        --name $stateAccountName `
        --resource-group $StateResourceGroup `
        --location $Region `
        --sku Standard_LRS `
        --encryption-services blob `
        --min-tls-version TLS1_2 `
        --allow-blob-public-access false
    
    # Create container
    az storage container create `
        --name tfstate `
        --account-name $stateAccountName `
        --auth-mode login
    
    Write-Host "✓ State storage created" -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# Step 6: Initialize Terraform Backends
# -----------------------------------------------------------------------------

Write-Host "`n[6/6] Initializing Terraform backends..." -ForegroundColor Yellow

$components = @("management", "hub", "spokes\production")

foreach ($component in $components) {
    $componentPath = "terraform\environments\$CustomerId\$component"
    Write-Host "  Initializing: $component" -ForegroundColor Gray
    
    Push-Location $componentPath
    
    # Update backend config with customer-specific values
    $backendConfig = @"
resource_group_name  = "$StateResourceGroup"
storage_account_name = "$stateAccountName"
container_name       = "tfstate"
"@
    
    terraform init -backend-config="$backendConfig" -reconfigure
    
    Pop-Location
}

Write-Host "✓ Terraform backends initialized" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✓ Customer Onboarded Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nCustomer ID: $CustomerId" -ForegroundColor White
Write-Host "Region: $Region ($regionCode)" -ForegroundColor White
Write-Host "Environment: $Environment" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Update customer config: customers\$CustomerId\config.yaml" -ForegroundColor White
Write-Host "2. Add Azure credentials (Service Principal)" -ForegroundColor White
Write-Host "3. Update terraform.tfvars files in each component" -ForegroundColor White
Write-Host "4. Run deployment: .\scripts\deploy.ps1 -CustomerId $CustomerId" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Cyan