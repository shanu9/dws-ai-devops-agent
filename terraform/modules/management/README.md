# Management Module - Azure CAF Landing Zone

Deploys the centralized Management subscription for monitoring, logging, security, policy enforcement, backup, and cost management across all Hub and Spoke subscriptions.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Components](#components)
- [Log Analytics Strategy](#log-analytics-strategy)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Cost Optimization](#cost-optimization)
- [Security Best Practices](#security-best-practices)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## 🏗️ Overview

The Management module creates the central monitoring and governance infrastructure that:
- **Centralizes all logs** - Multi-workspace LAW with tag-based retention
- **Monitors everything** - Proactive KQL alerts with email notifications
- **Enforces compliance** - Azure Policy and Defender for Cloud
- **Controls costs** - Budgets, alerts, and cost allocation tags
- **Protects data** - Azure Backup and disaster recovery
- **Enables automation** - Automation Account for runbooks

### Key Features

✅ **Multi-Workspace LAW** - Separate workspaces per team with different retention  
✅ **Tag-Based Cost Allocation** - Split costs across all spokes  
✅ **Table-Level Retention** - Different retention per log type (save 70% on costs)  
✅ **Read-Only Access** - Cross-subscription log visibility (from your diagram)  
✅ **Long-Term Archival** - Storage account for 7-year compliance retention  
✅ **Proactive Monitoring** - KQL alert rules with Action Groups  
✅ **Security Posture** - Microsoft Defender for Cloud  
✅ **Backup & DR** - Recovery Services Vault  
✅ **Cost Control** - Budgets with multi-threshold alerts  

---

## 🏛️ Architecture


┌─────────────────────────────────────────────────────────────────┐
│              Management Subscription                            │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │         LOG ANALYTICS WORKSPACES (Multi-Workspace)     │    │
│  │                                                        │    │
│  │  ┌──────────────────┐  ┌─────────────────────────┐   │    │
│  │  │  Central LAW     │  │  Team Workspaces        │   │    │
│  │  │  (90 days)       │  │  - Operations (90d)     │   │    │
│  │  │                  │  │  - Security (2 years)   │   │    │
│  │  │  All diagnostic  │  │  - Audit (7 years)      │   │    │
│  │  │  logs from:      │  │                         │   │    │
│  │  │  • Hub           │  │  Tag-based routing      │   │    │
│  │  │  • Spokes        │  │  Cost allocation tags   │   │    │
│  │  │  • Services      │  │                         │   │    │
│  │  └──────────────────┘  └─────────────────────────┘   │    │
│  │                                                        │    │
│  │  Table-Level Retention:                               │    │
│  │  • SecurityEvent    → 2 years (archive after 1yr)     │    │
│  │  • AuditLogs        → 7 years (compliance)            │    │
│  │  • Perf/Heartbeat   → 30 days (operational)           │    │
│  │  • Firewall logs    → 90 days (archive after 60d)     │    │
│  │  • Cost data        → 1 year (trend analysis)         │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │         COST ALLOCATION & SPLITTING                    │    │
│  │  Tags:                                                 │    │
│  │  • spoke-prod  → TeamA-Operations (chargeback)        │    │
│  │  • spoke-dev   → TeamB-Operations (no chargeback)     │    │
│  │  • hub         → Shared-Infrastructure                │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │         LONG-TERM ARCHIVAL (Storage Account)           │    │
│  │  • Hot tier    → 0-30 days                             │    │
│  │  • Cool tier   → 30-90 days                            │    │
│  │  • Archive tier → 90+ days (7 years compliance)        │    │
│  │  Cost: $0.01/GB/month (vs $2.30/GB in LAW)            │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │         AZURE MONITOR & ALERTS                         │    │
│  │  • Action Groups → Email notifications                 │    │
│  │  • KQL Alert Rules:                                    │    │
│  │    - High firewall denies                              │    │
│  │    - VM high CPU                                       │    │
│  │    - Cost spike detected                               │    │
│  │    - Security threats                                  │    │
│  │  • Read-only KQL queries (cross-subscription)          │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │         GOVERNANCE & SECURITY                          │    │
│  │  • Azure Policy     → CAF compliance enforcement       │    │
│  │  • Defender         → Security posture management      │    │
│  │  • Backup Vault     → VM & database protection         │    │
│  │  • Automation       → Cost optimization runbooks       │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │         COST MANAGEMENT                                │    │
│  │  • Monthly Budget   → Alert at 80%, 100%, 120%         │    │
│  │  • Cost Splitting   → Per spoke/team allocation        │    │
│  │  • Optimization     → Automated recommendations        │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
│                    │                    │
│ Read Access        │ Logs Flow          │ Policies Apply
↓                    ↓                    ↓
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  TeamA-Ops      │  │  Hub            │  │  Spoke 1        │
│  (90d access)   │  │  Subscription   │  │  Subscription   │
└─────────────────┘  └─────────────────┘  └─────────────────┘
┌─────────────────┐
│  TeamA-Security │
│  (2yr access)   │
└─────────────────┘
┌─────────────────┐
│  TeamB-Audit    │
│  (7yr access)   │
└─────────────────┘

---

## 📦 Components

### Core Components (Always Deployed)

| Component | Purpose | Cost Impact |
|-----------|---------|-------------|
| **Central LAW** | Primary log aggregation | High ($2.30/GB) |
| **Resource Group** | Container for all resources | Free |
| **Automation Account** | Runbooks for automation | Low ($0.002/min) |
| **Storage Account** | Long-term log archival | Very Low ($0.01/GB) |

### Optional Components (Configurable)

| Component | Purpose | Default | Cost Impact |
|-----------|---------|---------|-------------|
| **Team Workspaces** | Per-team log segregation | Enabled | Medium |
| **Action Groups** | Email notifications | Enabled | Free |
| **KQL Alert Rules** | Proactive monitoring | Enabled | Free |
| **Azure Policy** | Governance enforcement | Enabled | Free |
| **Defender for Cloud** | Security posture | Enabled | Medium-High |
| **Recovery Services Vault** | Backup & DR | Enabled | Per-VM cost |
| **Event Hub** | SIEM integration | Disabled | Medium |
| **Cost Budgets** | Spending alerts | Enabled | Free |

---

## 📊 Log Analytics Strategy

### Multi-Workspace Architecture (From Your Diagram)

#### **Central LAW** - Primary workspace
- **Retention**: 90 days (configurable)
- **Purpose**: All diagnostic logs from Hub/Spokes
- **Access**: Read-only for all teams
- **Cost**: $2.30/GB ingestion + $0.10/GB/day retention

#### **Team Workspaces** - Segregated by team

1. **Operations Workspace** (`law-{customer}-operations-{region}`)
   - **Retention**: 90 days
   - **Purpose**: Operational logs and metrics
   - **Access**: TeamA-Operations (read-only)
   - **Tags**: `Team=Operations`, `CostCenter=TeamA`

2. **Security Workspace** (`law-{customer}-security-{region}`)
   - **Retention**: 730 days (2 years)
   - **Purpose**: Security and compliance logs
   - **Access**: TeamA-Security (read-only)
   - **Tags**: `Team=Security`, `CostCenter=TeamA`

3. **Audit Workspace** (`law-{customer}-audit-{region}`)
   - **Retention**: 2555 days (7 years - compliance requirement)
   - **Purpose**: Audit and regulatory logs
   - **Access**: TeamB-Audit (read-only)
   - **Tags**: `Team=Audit`, `CostCenter=TeamB`

### Table-Level Retention (Cost Optimization)

Different log types have different retention needs:
```hcl
# Security logs - Long retention
SecurityEvent       → 730 days active + 730 archive = 2 years
AuditLogs           → 2555 days = 7 years (compliance)

# Operational logs - Short retention
Perf                → 30 days (metrics)
Heartbeat           → 30 days (availability)

# Firewall logs - Medium retention
AzureFirewallRule   → 90 days active + 60 archive

# Cost data - Long retention for trend analysis
AzureCostManagement → 365 days
Cost Savings:

Active retention: $0.10/GB/day
Archive retention: $0.02/GB/day (80% cheaper)
Storage account: $0.01/GB/month (97% cheaper)

Basic Logs Tier (80% Cost Savings)
High-volume, low-query logs use Basic tier:

Cost: $0.50/GB (vs $2.30/GB standard)
Retention: 8 days fixed
Query: Limited (no complex KQL)
Use for: Container logs, HTTP logs, verbose diagnostics


✅ Prerequisites
Azure Requirements

Azure Subscription

Owner or Contributor role
Resource Provider registered: Microsoft.Insights, Microsoft.OperationalInsights, Microsoft.Security


Permissions

Create Log Analytics Workspaces
Assign Azure Policies
Configure Defender for Cloud


Naming Standards

Customer ID: 3-6 lowercase alphanumeric
Region code: 2-4 lowercase letters



Terraform Requirements
hclterraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

🚀 Usage
Basic Usage (Minimum Configuration)
hclmodule "management" {
  source = "../../modules/management"
  
  # Required variables
  customer_id = "abc"
  environment = "prd"
  region      = "eastus"
  region_code = "eus"
  
  # Central LAW (required by Hub/Spoke)
  enable_central_law        = true
  central_law_retention_days = 90
  
  # Alert notifications
  alert_email_receivers = [
    "ops-team@company.com",
    "security-team@company.com"
  ]
  
  # Tags
  tags = {
    Project    = "CAF-LZ"
    Owner      = "Platform-Team"
    CostCenter = "IT-Management"
  }
}
Production Configuration (Multi-Workspace with Cost Optimization)
hclmodule "management" {
  source = "../../modules/management"
  
  # Identity
  customer_id = "contoso"
  environment = "prd"
  region      = "eastus"
  region_code = "eus"
  
  # =========================================================================
  # CENTRAL LOG ANALYTICS WORKSPACE
  # =========================================================================
  
  enable_central_law         = true
  central_law_sku            = "PerGB2018"
  central_law_retention_days = 90
  central_law_daily_quota_gb = 100  # Cost control: $230/day max
  
  # Commitment tier for cost savings (15-30% discount)
  enable_commitment_tiers = true
  commitment_tier_gb      = 100  # 100GB/day commitment
  
  # =========================================================================
  # TEAM WORKSPACES (Per Your Diagram)
  # =========================================================================
  
  enable_team_workspaces = true
  
  team_workspaces = {
    "operations" = {
      retention_days = 90    # LAW-TeamA-Operations (90 days)
      daily_quota_gb = 50
      purpose        = "Operational logs and metrics"
    }
    "security" = {
      retention_days = 730   # LAW-TeamA-Security (2 years)
      daily_quota_gb = 100
      purpose        = "Security and compliance logs"
    }
    "audit" = {
      retention_days = 2555  # LAW-TeamB-Audit (7 years)
      daily_quota_gb = 30
      purpose        = "Audit and regulatory logs"
    }
  }
  
  # =========================================================================
  # TABLE-LEVEL RETENTION (Granular Cost Control)
  # =========================================================================
  
  enable_table_retention = true
  
  table_retention_overrides = {
    # Security - Long retention
    "SecurityEvent" = {
      retention_days = 730
      archive_days   = 365
    }
    "AuditLogs" = {
      retention_days = 2555
      archive_days   = 730
    }
    
    # Operational - Short retention
    "Perf" = {
      retention_days = 30
      archive_days   = 0
    }
    "Heartbeat" = {
      retention_days = 30
      archive_days   = 0
    }
    
    # Firewall - Medium retention
    "AzureFirewallApplicationRule" = {
      retention_days = 90
      archive_days   = 60
    }
    "AzureFirewallNetworkRule" = {
      retention_days = 90
      archive_days   = 60
    }
    
    # Cost - Long for trends
    "AzureCostManagement" = {
      retention_days = 365
      archive_days   = 180
    }
  }
  
  # Basic logs tier (80% cost savings)
  enable_basic_logs = true
  basic_log_tables = [
    "ContainerLog",
    "AppServiceConsoleLogs",
    "AppServiceHTTPLogs"
  ]
  
  # =========================================================================
  # COST ALLOCATION (Tag-Based Split Across Spokes)
  # =========================================================================
  
  enable_cost_splitting = true
  
  cost_allocation_tags = {
    "spoke-prod" = {
      cost_center    = "Production-Workloads"
      team           = "TeamA-Operations"
      chargeback     = true
      budget_alert   = 50000
    }
    "spoke-dev" = {
      cost_center    = "Development"
      team           = "TeamB-Operations"
      chargeback     = false
      budget_alert   = 10000
    }
    "hub" = {
      cost_center    = "Shared-Infrastructure"
      team           = "Platform"
      chargeback     = false
      budget_alert   = 15000
    }
  }
  
  # =========================================================================
  # LONG-TERM ARCHIVAL (Storage Account for 7-Year Compliance)
  # =========================================================================
  
  enable_log_export          = true
  log_export_retention_days  = 2555  # 7 years in blob storage
  
  # Event Hub for SIEM (optional)
  enable_event_hub_export = false
  
  # =========================================================================
  # MONITORING & ALERTS
  # =========================================================================
  
  enable_azure_monitor  = true
  enable_action_groups  = true
  enable_kql_alert_rules = true
  
  alert_email_receivers = [
    "ops-team@contoso.com",
    "security@contoso.com",
    "cto@contoso.com"
  ]
  
  # Custom alert rules
  alert_rules = {
    "high-firewall-denies" = {
      query = <<-QUERY
        AzureFirewallNetworkRule
        | where Action == "Deny"
        | summarize DenyCount = count() by bin(TimeGenerated, 5m)
        | where DenyCount > 100
      QUERY
      severity    = 2
      frequency   = 5
      time_window = 15
      threshold   = 100
    }
    "cost-spike-detected" = {
      query = <<-QUERY
        AzureCostManagement
        | summarize TodayCost = sum(Cost) by bin(TimeGenerated, 1d)
        | extend AvgCost = avg(TodayCost)
        | where TodayCost > AvgCost * 1.5
      QUERY
      severity    = 2
      frequency   = 60
      time_window = 120
      threshold   = 1
    }
  }
  
  # =========================================================================
  # GOVERNANCE & SECURITY
  # =========================================================================
  
  # Azure Policy
  enable_azure_policy      = true
  policy_assignment_mode   = "Default"  # Enforce policies
  enable_builtin_policies  = true
  
  # Microsoft Defender for Cloud
  enable_defender = true
  
  defender_plans = {
    "VirtualMachines" = {
      tier    = "Standard"
      enabled = true
    }
    "SqlServers" = {
      tier    = "Standard"
      enabled = true
    }
    "StorageAccounts" = {
      tier    = "Standard"
      enabled = true
    }
    "KeyVaults" = {
      tier    = "Standard"
      enabled = true
    }
  }
  
  # =========================================================================
  # BACKUP & DISASTER RECOVERY
  # =========================================================================
  
  enable_backup_vault = true
  
  backup_policy_vm = {
    frequency         = "Daily"
    time              = "23:00"
    retention_daily   = 30
    retention_weekly  = 12
    retention_monthly = 12
    retention_yearly  = 7
  }
  
  # =========================================================================
  # COST MANAGEMENT
  # =========================================================================
  
  enable_cost_management = true
  enable_budgets         = true
  monthly_budget_limit   = 150000  # $150K/month total budget
  
  budget_alert_thresholds = [80, 100, 120]  # Alert at 80%, 100%, 120%
  
  # =========================================================================
  # RBAC (Read-Only Access Per Team)
  # =========================================================================
  
  enable_rbac_assignments = true
  
  log_analytics_readers = {
    "operations" = [
      "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"  # TeamA-Operations AAD Group
    ]
    "security" = [
      "bbbbbbbb-cccc-dddd-eeee-ffffffffffff"  # TeamA-Security AAD Group
    ]
    "audit" = [
      "cccccccc-dddd-eeee-ffff-gggggggggggg"  # TeamB-Audit AAD Group
    ]
  }
  
  # Tags
  tags = {
    Project       = "Enterprise-Management"
    Owner         = "Platform-Team"
    CostCenter    = "IT-Management"
    Criticality   = "Critical"
    Compliance    = "ISO27001"
  }
}
Cost-Optimized Configuration (Development)
hclmodule "management" {
  source = "../../modules/management"
  
  customer_id = "dev"
  environment = "dev"
  region      = "eastus"
  region_code = "eus"
  
  # Central LAW only (no team workspaces)
  enable_central_law         = true
  central_law_retention_days = 30  # Shorter retention
  central_law_daily_quota_gb = 10  # Smaller quota
  
  enable_team_workspaces = false  # Cost saving
  
  # Basic monitoring
  enable_action_groups   = true
  enable_kql_alert_rules = false  # Reduce noise in dev
  
  alert_email_receivers = ["dev-team@company.com"]
  
  # Minimal security
  enable_defender = false  # Free tier only
  
  # No backup in dev
  enable_backup_vault = false
  
  # No budget (dev environment)
  enable_budgets = false
  
  tags = {
    Environment = "Development"
    AutoShutdown = "Allowed"
  }
}

📥 Inputs
Required Inputs
NameTypeDescriptioncustomer_idstringUnique customer identifier (3-6 chars)regionstringAzure region (e.g., eastus)region_codestringShort region code (e.g., eus)
Log Analytics Configuration
NameTypeDefaultDescriptionenable_central_lawbooltrueDeploy central LAWcentral_law_skustring"PerGB2018"LAW pricing SKUcentral_law_retention_daysnumber90Default retention (30-730 days)central_law_daily_quota_gbnumber-1Daily ingestion limit (-1 = unlimited)enable_team_workspacesbooltrueCreate per-team workspacesteam_workspacesmap(object)See belowTeam workspace configuration
Default Team Workspaces:
hcl{
  "operations" = {
    retention_days = 90
    daily_quota_gb = 50
    purpose        = "Operational logs"
  }
  "security" = {
    retention_days = 730
    daily_quota_gb = 100
    purpose        = "Security logs"
  }
  "audit" = {
    retention_days = 2555
    daily_quota_gb = 30
    purpose        = "Audit logs"
  }
}
Cost Optimization
NameTypeDefaultDescriptionenable_commitment_tiersboolfalseUse commitment pricing (15-30% savings)commitment_tier_gbnumber100Commitment level (100-5000 GB/day)enable_basic_logsbooltrueUse Basic logs tier (80% savings)enable_table_retentionbooltrueTable-level retention configuration
Monitoring & Alerts
NameTypeDefaultDescriptionenable_action_groupsbooltrueCreate Action Groupsalert_email_receiverslist(string)[]Email addresses for alertsenable_kql_alert_rulesbooltrueDeploy KQL alert rules
Security & Governance
NameTypeDefaultDescriptionenable_azure_policybooltrueDeploy Azure Policyenable_defenderbooltrueEnable Defender for Cloudenable_backup_vaultbooltrueDeploy Recovery Services Vault
Cost Management
NameTypeDefaultDescriptionenable_budgetsbooltrueCreate cost budgetsmonthly_budget_limitnumber0Monthly budget in USD (0 = no limit)budget_alert_thresholdslist(number)[80,100,120]Alert thresholds (%)
See variables.tf for complete list.

📤 Outputs
Critical Outputs (Most Used)
OutputDescriptionUsed Bycentral_workspace_idCentral LAW IDHub, Spoke modulesteam_workspace_idsMap of team workspace IDsRBAC, routinglaw_configComplete LAW configurationAll modulesaction_group_idAction Group IDAlert rulesbackup_vault_idRecovery Vault IDVM backup
LAW Outputs
hcloutput "central_workspace_id"         # Required by Hub/Spoke
output "central_workspace_name"
output "central_workspace_customer_id" # For agent config
output "team_workspaces"              # Map of all team workspaces
output "operations_workspace_id"
output "security_workspace_id"
output "audit_workspace_id"
Cost Tracking Outputs
hcloutput "cost_tracking"  # Complete cost data for intelligence engine
  - customer_id
  - cost_allocation_tags
  - LAW costs (SKU, retention, quota)
  - Team workspace costs
  - Storage costs
  - Defender costs
  - Resource IDs for cost queries
Integration Outputs
hcloutput "monitoring_config"  # Everything Hub/Spoke need
  - workspace_id
  - action_group_id
  - backup_vault_id
  - log_storage_id
See outputs.tf for complete documentation.

💰 Cost Optimization
Monthly Cost Estimates (USD)
ConfigurationCentral LAWTeam LAWsStorageDefenderTotal/MonthMinimum (Dev)$300$0$50$0~$350Standard (Prod)$1,500$1,000$200$500~$3,200Enterprise (Multi-Team)$3,000$2,500$500$1,500~$7,500
Assumptions:

Central LAW: 50GB/day @ $2.30/GB = $3,450/month (with 30% commitment discount = $2,415)
Team LAWs: 3 workspaces × 20GB/day = $1,380/month
Storage: 10TB archived @ $0.02/GB = $200/month
Defender: 50 VMs @ $10/VM = $500/month

Cost Optimization Strategies
1. Commitment Tiers (15-30% Savings)
hcl# Standard pricing: $2.30/GB
# Commitment pricing:
#   100GB/day:   $1.84/GB (20% off)
#   500GB/day:   $1.61/GB (30% off)
#   1000GB/day:  $1.61/GB (30% off)

enable_commitment_tiers = true
commitment_tier_gb      = 100  # Match your average daily ingestion

# Savings: $2,300/month → $1,840/month = $460/month saved
2. Basic Logs Tier (80% Savings)
hcl# High-volume, low-query logs
# Standard: $2.30/GB
# Basic:    $0.50/GB (78% cheaper!)

enable_basic_logs = true
basic_log_tables = [
  "ContainerLog",        # 10GB/day × $0.50 = $150/month (vs $690)
  "AppServiceConsoleLogs",
  "AppServiceHTTPLogs"
]

# Savings: $540/month per 10GB/day
3. Table-Level Retention (70% Savings)
hcl# Keep expensive active logs short
# Archive to cheaper storage

table_retention_overrides = {
  "Perf" = {
    retention_days = 30      # Active: $0.10/GB/day
    archive_days   = 0
  }
  "SecurityEvent" = {
    retention_days = 365     # Active: 1 year
    archive_days   = 365     # Archive: 1 more year @ $0.02/GB/day
  }
}

# Example: 1GB SecurityEvent
# Active 2yr:  730 days × $0.10 = $73
# Active 1yr + Archive 1yr: (365 × $0.10) + (365 × $0.02) = $36.50 + $7.30 = $43.80
# Savings: $29.20/GB (40% off)
4. Storage Account Archival (97% Savings)
hcl# Export old logs to Storage Account

enable_log_export         = true
log_export_retention_days = 2555  # 7 years

# Cost comparison for 1TB:
# LAW (365 days): 1000GB × 365 × $0.10 = $36,500/year
# Storage (Hot):  1000GB × $0.02 × 12 = $240/year
# Storage (Cool): 1000GB × $0.01 × 12 = $120/year
# Storage (Archive): 1000GB × $0.002 × 12 = $24/year

# Savings: $36,476/year (99.9% cheaper!)
5. Daily Quota (Cost Control)
hcl# Prevent cost overruns

central_law_daily_quota_gb = 100  # $230/day max

# If exceeded: Ingestion stops until next day
# Alert sent to Action Group