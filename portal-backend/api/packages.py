"""
Packages API
GET /api/packages - List all packages
"""
from fastapi import APIRouter, HTTPException
from typing import List, Dict

router = APIRouter(prefix="/api/packages", tags=["packages"])

PACKAGES = {
    "basic": {
        "tier": "basic",
        "name": "Basic",
        "description": "Essential cloud infrastructure for small teams",
        "monthly_cost": 1500.0,
        "highlights": [
            "Standard Firewall",
            "Key Vault",
            "30-day log retention",
            "5 VMs maximum",
            "Community support"
        ],
        "features": {
            "firewall_sku": "Standard",
            "enable_bastion": False,
            "enable_vpn": False,
            "max_vms": 5,
            "log_retention_days": 30
        },
        "color": "blue"
    },
    "standard": {
        "tier": "standard",
        "name": "Standard",
        "description": "Complete solution for growing businesses",
        "monthly_cost": 3500.0,
        "highlights": [
            "Azure Bastion included",
            "SQL Database",
            "Data Factory",
            "90-day log retention",
            "Microsoft Defender",
            "20 VMs maximum",
            "Business hours support"
        ],
        "features": {
            "firewall_sku": "Standard",
            "enable_bastion": True,
            "enable_vpn": False,
            "enable_sql": True,
            "enable_datafactory": True,
            "max_vms": 20,
            "log_retention_days": 90
        },
        "color": "green",
        "recommended": True
    },
    "premium": {
        "tier": "premium",
        "name": "Premium",
        "description": "Enterprise-grade with advanced security",
        "monthly_cost": 6500.0,
        "highlights": [
            "Premium Firewall with IDS/IPS",
            "VPN Gateway",
            "DDoS Protection",
            "AKS Cluster",
            "365-day log retention",
            "100 VMs maximum",
            "24/7 premium support"
        ],
        "features": {
            "firewall_sku": "Premium",
            "enable_bastion": True,
            "enable_vpn": True,
            "enable_sql": True,
            "enable_datafactory": True,
            "enable_aks": True,
            "max_vms": 100,
            "log_retention_days": 365
        },
        "color": "purple"
    }
}

@router.get("/")
async def list_packages() -> List[Dict]:
    """Get all available packages"""
    return list(PACKAGES.values())

@router.get("/{tier}")
async def get_package(tier: str) -> Dict:
    """Get specific package details"""
    if tier not in PACKAGES:
        raise HTTPException(status_code=404, detail="Package not found")
    return PACKAGES[tier]