<#
.SYNOPSIS
    End-to-end infrastructure deployment
.DESCRIPTION
    Reads Excel parameters, generates tfvars, validates, and deploys
.PARAMETER ExcelFile
    Path to deployment-parameters.xlsx
.PARAMETER Component
    What to deploy: All, Management, Hub, Spoke
#>

param(
    [string]$ExcelFile = "deployment-parameters.xlsx",
    [ValidateSet("All", "Management", "Hub", "Spoke")]
    [string]$Component = "All",
    [string]$SpokeName = "production"
)

Write-Host "🚀 CAF-LZ Deployment Automation" -ForegroundColor Cyan
Write-Host "=" * 60

# Step 1: Generate tfvars from Excel
Write-Host "`n📊 Step 1: Generating Terraform variables..." -ForegroundColor Yellow
python scripts/generate-tfvars.py $ExcelFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to generate tfvars"
    exit 1
}

# Step 2: Pre-flight checks
Write-Host "`n✅ Step 2: Running pre-flight checks..." -ForegroundColor Yellow
az account show | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Not logged into Azure. Run 'az login'"
    exit 1
}

# Step 3: Deploy Management (if requested)
if ($Component -in @("All", "Management")) {
    Write-Host "`n🏢 Step 3: Deploying Management..." -ForegroundColor Yellow
    Push-Location terraform/environments/test-customer/management
    terraform init
    terraform plan -out=tfplan
    terraform apply tfplan
    Pop-Location
}

# Step 4: Deploy Hub (if requested)
if ($Component -in @("All", "Hub")) {
    Write-Host "`n🌐 Step 4: Deploying Hub..." -ForegroundColor Yellow
    Push-Location terraform/environments/test-customer/hub
    terraform init
    terraform plan -out=tfplan
    terraform apply tfplan
    Pop-Location
}

# Step 5: Deploy Spoke (if requested)
if ($Component -in @("All", "Spoke")) {
    Write-Host "`n📦 Step 5: Deploying Spoke: $SpokeName..." -ForegroundColor Yellow
    Push-Location "terraform/environments/test-customer/spokes/$SpokeName"
    
    # Pre-deployment fixes
    Write-Host "  → Enabling public network access..." -ForegroundColor Gray
    $storageAccount = "st$(Get-Content terraform.tfvars | Select-String 'customer_id').Split('=')[1].Trim().Replace('"','')$(Get-Content terraform.tfvars | Select-String 'spoke_name').Split('=')[1].Trim().Replace('"','')$(Get-Content terraform.tfvars | Select-String 'region_code').Split('=')[1].Trim().Replace('"','')"
    
    terraform init
    terraform plan -out=tfplan
    terraform apply tfplan
    Pop-Location
}

Write-Host "`n✅ Deployment Complete!" -ForegroundColor Green