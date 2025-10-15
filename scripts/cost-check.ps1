# =============================================================================
# COST CHECK - Analyze Customer Costs
# =============================================================================
# Usage: .\cost-check.ps1 -CustomerId "contoso"

param(
    [Parameter(Mandatory=$true)]
    [string]$CustomerId,
    
    [Parameter(Mandatory=$false)]
    [int]$Days = 30
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Cost Analysis: $CustomerId" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Load customer config
$configPath = "customers\$CustomerId\config.yaml"
if (!(Test-Path $configPath)) {
    Write-Error "Customer not found: $CustomerId"
}

# Get Azure costs via Azure CLI
Write-Host "`nFetching costs for last $Days days..." -ForegroundColor Yellow

$endDate = Get-Date -Format "yyyy-MM-dd"
$startDate = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-dd")

# Query Azure Cost Management API
$query = @"
{
  "type": "ActualCost",
  "timeframe": "Custom",
  "timePeriod": {
    "from": "$startDate",
    "to": "$endDate"
  },
  "dataset": {
    "granularity": "Daily",
    "aggregation": {
      "totalCost": {
        "name": "Cost",
        "function": "Sum"
      }
    },
    "grouping": [
      {
        "type": "Tag",
        "name": "Customer"
      },
      {
        "type": "Dimension",
        "name": "ResourceType"
      }
    ],
    "filter": {
      "tags": {
        "name": "Customer",
        "operator": "In",
        "values": ["$CustomerId"]
      }
    }
  }
}
"@

# Execute cost query
Write-Host "  Analyzing costs..." -ForegroundColor Gray

# Mock output (replace with actual Azure CLI call)
Write-Host "`n✓ Cost Summary:" -ForegroundColor Green
Write-Host "  Total Cost (Last $Days days): `$X,XXX.XX" -ForegroundColor White
Write-Host "  Average Daily Cost: `$XXX.XX" -ForegroundColor White
Write-Host "  Trend: ↑ 5% vs previous period" -ForegroundColor Yellow

Write-Host "`nTop Cost Drivers:" -ForegroundColor Yellow
Write-Host "  1. Azure Firewall: `$XXX (XX%)" -ForegroundColor White
Write-Host "  2. Log Analytics: `$XXX (XX%)" -ForegroundColor White
Write-Host "  3. VMs: `$XXX (XX%)" -ForegroundColor White
Write-Host "  4. SQL Database: `$XXX (XX%)" -ForegroundColor White
Write-Host "  5. Storage: `$XXX (XX%)" -ForegroundColor White

Write-Host "`n💡 Cost Optimization Recommendations:" -ForegroundColor Cyan
Write-Host "  • Consider reserved instances for VMs (save 30-50%)" -ForegroundColor Gray
Write-Host "  • Enable SQL serverless auto-pause (save 20-40%)" -ForegroundColor Gray
Write-Host "  • Use commitment tiers for Log Analytics (save 15-30%)" -ForegroundColor Gray

Write-Host "`n========================================`n" -ForegroundColor Cyan