# =============================================================================
# DEPLOY INFRASTRUCTURE - Deploy Hub + Management + Spoke + Services
# =============================================================================
# Usage: .\deploy.ps1 -CustomerId "contoso" -Components "all"

param(
    [Parameter(Mandatory=$true)]
    [string]$CustomerId,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "management", "hub", "spoke", "services")]
    [string]$Components = "all",
    
    [Parameter(Mandatory=$false)]
    [string]$SpokeName = "production",
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoApprove = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment: $CustomerId" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

function Deploy-Component {
    param(
        [string]$Name,
        [string]$Path,
        [bool]$IsFirstDeployment = $false
    )
    
    Write-Host "`n[Deploying: $Name]" -ForegroundColor Yellow
    Write-Host "Path: $Path" -ForegroundColor Gray
    
    Push-Location $Path
    
    try {
        # Terraform init (refresh backend)
        Write-Host "  Running: terraform init..." -ForegroundColor Gray
        terraform init -upgrade
        
        # Terraform validate
        Write-Host "  Running: terraform validate..." -ForegroundColor Gray
        terraform validate
        
        # Terraform plan
        Write-Host "  Running: terraform plan..." -ForegroundColor Gray
        
        if ($DryRun) {
            terraform plan -out=tfplan
            Write-Host "✓ Dry run complete (plan saved)" -ForegroundColor Green
            Pop-Location
            return
        }
        
        terraform plan -out=tfplan
        
        # Terraform apply
        if ($AutoApprove) {
            Write-Host "  Running: terraform apply (auto-approve)..." -ForegroundColor Gray
            terraform apply tfplan
        } else {
            Write-Host "`n  Review the plan above." -ForegroundColor Yellow
            $confirm = Read-Host "  Apply changes? (yes/no)"
            
            if ($confirm -eq "yes") {
                terraform apply tfplan
            } else {
                Write-Host "✗ Deployment cancelled" -ForegroundColor Red
                Pop-Location
                exit 1
            }
        }
        
        Write-Host "✓ $Name deployed successfully" -ForegroundColor Green
        
    } catch {
        Write-Error "Failed to deploy $Name : $_"
    } finally {
        Pop-Location
    }
}

# -----------------------------------------------------------------------------
# Deployment Order (CRITICAL: Must follow dependencies)
# -----------------------------------------------------------------------------

$basePath = "terraform\environments\$CustomerId"

# Check customer exists
if (!(Test-Path "customers\$CustomerId")) {
    Write-Error "Customer not found. Run setup-customer.ps1 first."
}

Write-Host "`nCustomer: $CustomerId" -ForegroundColor White
Write-Host "Components: $Components" -ForegroundColor White
Write-Host "Dry Run: $DryRun" -ForegroundColor White
Write-Host ""

# Deployment order (dependencies)
$deploymentSteps = @()

if ($Components -eq "all" -or $Components -eq "management") {
    $deploymentSteps += @{
        Name = "Management"
        Path = "$basePath\management"
        IsFirst = $true
    }
}

if ($Components -eq "all" -or $Components -eq "hub") {
    $deploymentSteps += @{
        Name = "Hub"
        Path = "$basePath\hub"
    }
}

if ($Components -eq "all" -or $Components -eq "spoke" -or $Components -eq "services") {
    $deploymentSteps += @{
        Name = "Spoke: $SpokeName"
        Path = "$basePath\spokes\$SpokeName"
    }
}

# -----------------------------------------------------------------------------
# Execute Deployments
# -----------------------------------------------------------------------------

$startTime = Get-Date

foreach ($step in $deploymentSteps) {
    Deploy-Component -Name $step.Name -Path $step.Path -IsFirstDeployment $step.IsFirst
    
    Start-Sleep -Seconds 5  # Brief pause between components
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

$duration = (Get-Date) - $startTime

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✓ Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nCustomer: $CustomerId" -ForegroundColor White
Write-Host "Components: $Components" -ForegroundColor White
Write-Host "Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor White

if (!$DryRun) {
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "1. Verify resources in Azure Portal" -ForegroundColor White
    Write-Host "2. Check logs in Log Analytics Workspace" -ForegroundColor White
    Write-Host "3. Test connectivity (VNet peering, private endpoints)" -ForegroundColor White
    Write-Host "4. Run cost analysis: .\scripts\cost-check.ps1 -CustomerId $CustomerId" -ForegroundColor White
}

Write-Host "`n========================================`n" -ForegroundColor Cyan