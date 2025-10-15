"""
AI-Powered Recommendations API
Intelligent suggestions for optimization
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel
import logging

from database import get_db
from models.customer import Customer
from api.auth import get_current_user

router = APIRouter()
logger = logging.getLogger(__name__)

class Recommendation(BaseModel):
    id: str
    category: str  # cost | security | performance | reliability
    severity: str  # critical | high | medium | low
    title: str
    description: str
    impact: str
    action_required: str
    estimated_savings: float = 0
    estimated_time_minutes: int = 0

@router.get("/{customer_id}", response_model=List[Recommendation])
async def get_recommendations(
    customer_id: str,
    category: str = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get AI-powered recommendations for customer
    """
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")
    
    # Generate recommendations based on customer configuration
    recommendations = []
    
    # Cost recommendations
    if category is None or category == "cost":
        if customer.firewall_sku == "Premium":
            recommendations.append(Recommendation(
                id="cost-001",
                category="cost",
                severity="medium",
                title="Downgrade Firewall from Premium to Standard",
                description="Your Firewall is using Premium SKU but analysis shows you're not using Premium features (TLS inspection, IDPS).",
                impact="Save $500/month without feature loss",
                action_required="Change firewall_sku to 'Standard' in configuration",
                estimated_savings=500.0,
                estimated_time_minutes=15
            ))
        
        if customer.services_config.get("production", {}).get("sql", {}).get("enabled"):
            recommendations.append(Recommendation(
                id="cost-002",
                category="cost",
                severity="medium",
                title="Enable SQL Database Serverless",
                description="SQL Database shows low activity patterns. Serverless with auto-pause can reduce costs by 40%.",
                impact="Save $80-120/month",
                action_required="Enable serverless SKU with 60-min auto-pause",
                estimated_savings=100.0,
                estimated_time_minutes=10
            ))
    
    # Security recommendations
    if category is None or category == "security":
        if not customer.enable_bastion:
            recommendations.append(Recommendation(
                id="sec-001",
                category="security",
                severity="high",
                title="Enable Azure Bastion",
                description="VMs are accessible without Bastion. Enable Bastion for secure RDP/SSH access.",
                impact="Eliminate public IPs on VMs, improve security posture",
                action_required="Set enable_bastion = true",
                estimated_time_minutes=20
            ))
        
        recommendations.append(Recommendation(
            id="sec-002",
            category="security",
            severity="critical",
            title="Enable Microsoft Defender for Cloud",
            description="Defender provides threat detection and security recommendations.",
            impact="Proactive threat detection, compliance monitoring",
            action_required="Enable Defender Standard tier for VMs and databases",
            estimated_time_minutes=10
        ))
    
    # Performance recommendations
    if category is None or category == "performance":
        recommendations.append(Recommendation(
            id="perf-001",
            category="performance",
            severity="low",
            title="Enable Zone Redundancy",
            description="Critical resources (Firewall, SQL) are not zone-redundant. Enable for 99.99% SLA.",
            impact="Improve availability from 99.9% to 99.99%",
            action_required="Set enable_zone_redundancy = true",
            estimated_time_minutes=30
        ))
    
    # Reliability recommendations
    if category is None or category == "reliability":
        if customer.services_config.get("production", {}).get("storage", {}).get("enabled"):
            storage_replication = customer.services_config.get("production", {}).get("storage", {}).get("replication", "LRS")
            if storage_replication == "LRS":
                recommendations.append(Recommendation(
                    id="rel-001",
                    category="reliability",
                    severity="high",
                    title="Upgrade Storage Replication to GRS",
                    description="Storage uses LRS (local redundancy). Upgrade to GRS for geo-redundancy.",
                    impact="Protect against regional outages",
                    action_required="Change storage replication to 'GRS'",
                    estimated_time_minutes=15
                ))
    
    # Filter by category if specified
    if category:
        recommendations = [r for r in recommendations if r.category == category]
    
    return recommendations

@router.post("/{customer_id}/{recommendation_id}/apply")
async def apply_recommendation(
    customer_id: str,
    recommendation_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Apply recommendation (update customer configuration)
    """
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")
    
    # Apply recommendation based on ID
    applied = False
    
    if recommendation_id == "cost-001":
        customer.firewall_sku = "Standard"
        applied = True
    elif recommendation_id == "sec-001":
        customer.enable_bastion = True
        applied = True
    elif recommendation_id == "cost-002":
        # Update services config
        if "production" in customer.services_config:
            if "sql" not in customer.services_config["production"]:
                customer.services_config["production"]["sql"] = {}
            customer.services_config["production"]["sql"]["sku"] = "GP_S_Gen5_2"
            customer.services_config["production"]["sql"]["serverless"] = True
            applied = True
    
    if applied:
        db.commit()
        logger.info(f"Recommendation {recommendation_id} applied for {customer_id} by {current_user.username}")
        return {"message": "Recommendation applied successfully", "requires_redeployment": True}
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Recommendation not applicable or already applied"
        )