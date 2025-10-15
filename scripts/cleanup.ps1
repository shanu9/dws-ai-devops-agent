# =============================================================================
# CLEANUP SCRIPT - Delete Customer Infrastructure
# =============================================================================
# Usage: .\cleanup.ps1 -CustomerId "test01"
# Purpose: Delete all Azure resources for a customer to avoid charges

param(
    [Parameter(Mandatory=$true)]
    [string]$CustomerId,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

Write-Info "=========================================="
Write-Info "Azure CAF-LZ Cleanup Script"
Write-Info "Customer ID: $CustomerId"
Write-Info "=========================================="

# Get all resource groups for this customer
$rgPattern = "rg-$CustomerId-*"
$resourceGroups = az group list --query "[?starts_with(name, 'rg-$CustomerId-')].name" -o tsv

if (-not $resourceGroups) {
    Write-Warning "No resource groups found for customer: $CustomerId"
    exit 0
}

Write-Info "`nFound resource groups:"
foreach ($rg in $resourceGroups) {
    Write-Info "  - $rg"
}

# Get resource count
$totalResources = 0
foreach ($rg in $resourceGroups) {
    $count = (az resource list --resource-group $rg --query "length(@)") | ConvertFrom-Json
    $totalResources += $count
    Write-Info "  $rg : $count resources"
}

Write-Warning "`nTotal resources to delete: $totalResources"

# Confirmation
if (-not $Force -and -not $DryRun) {
    $confirmation = Read-Host "`nAre you sure you want to DELETE all resources? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Info "Cleanup cancelled"
        exit 0
    }
}

if ($DryRun) {
    Write-Warning "`nDRY RUN MODE - No resources will be deleted"
    Write-Info "Resource groups that would be deleted:"
    foreach ($rg in $resourceGroups) {
        Write-Info "  - $rg"
    }
    exit 0
}

# Delete resource groups
Write-Info "`nStarting deletion..."
$deleteJobs = @()

foreach ($rg in $resourceGroups) {
    Write-Info "Deleting: $rg"
    
    # Start deletion in background
    $job = Start-Job -ScriptBlock {
        param($rgName)
        az group delete --name $rgName --yes --no-wait
    } -ArgumentList $rg
    
    $deleteJobs += $job
}

Write-Info "`nDeletion initiated for all resource groups"
Write-Info "Waiting for deletions to complete..."

# Wait for all jobs
$deleteJobs | Wait-Job | Out-Null

Write-Success "`n✅ Cleanup complete!"
Write-Info "All resource groups for customer '$CustomerId' have been deleted."

# Clean up Terraform state (optional)
$statePattern = "terraform/environments/$CustomerId"
if (Test-Path $statePattern) {
    Write-Warning "`nTerraform state directory still exists: $statePattern"
    $deleteState = Read-Host "Delete Terraform state directory? (yes/no)"
    if ($deleteState -eq "yes") {
        Remove-Item -Recurse -Force $statePattern
        Write-Success "Terraform state deleted"
    }
}

Write-Info "`n=========================================="
Write-Success "Cleanup Complete!"
Write-Info "=========================================="