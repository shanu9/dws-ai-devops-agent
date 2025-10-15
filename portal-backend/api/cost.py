"""
Cost Management & Intelligence API
Azure Cost analysis, recommendations, and budget tracking
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime, timedelta
from azure.identity import DefaultAzureCredential
from azure.mgmt.costmanagement import CostManagementClient
from azure.mgmt.costmanagement.models import QueryDefinition, TimeframeType
import logging

from database import get_db
from models.customer import Customer
from api.auth import get_current_user
from config import settings

router = APIRouter()
logger = logging.getLogger(__name__)

# Pydantic models
class CostSummary(BaseModel):
    customer_id: str
    period: str
    total_cost: float
    daily_average: float
    trend: str  # up | down | stable
    percentage_change: float
    budget_remaining: Optional[float]
    budget_percentage_used: Optional[float]

class CostByResource(BaseModel):
    resource_type: str
    resource_name: str
    cost: float
    percentage: float

class CostForecast(BaseModel):
    date: str
    forecasted_cost: float
    confidence: str

class CostRecommendation(BaseModel):
    resource_id: str
    resource_name: str
    recommendation_type: str  # rightsizing | unused | scheduling | reserved_instances
    current_cost: float
    potential_savings: float
    savings_percentage: float
    description: str
    action: str

# Azure Cost Management Client
def get_cost_client(subscription_id: str) -> CostManagementClient:
    """Initialize Azure Cost Management client"""
    credential = DefaultAzureCredential()
    return CostManagementClient(credential, subscription_id)

# Helper functions
def calculate_trend(current: float, previous: float) -> tuple[str, float]:
    """Calculate cost trend"""
    if previous == 0:
        return "stable", 0.0
    
    change = ((current - previous) / previous) * 100
    
    if abs(change) < 5:
        trend = "stable"
    elif change > 0:
        trend = "up"
    else:
        trend = "down"
    
    return trend, change

# Endpoints
@router.get("/{customer_id}/summary", response_model=CostSummary)
async def get_cost_summary(
    customer_id: str,
    days: int = 30,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get cost summary for customer
    """
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")
    
    try:
        # Get subscription IDs
        subscription_ids = customer.subscription_ids
        
        # Calculate date range
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days)
        
        # Mock data (replace with actual Azure Cost Management API calls)
        total_cost = 15432.50
        previous_period_cost = 14200.00
        daily_average = total_cost / days
        
        trend, percentage_change = calculate_trend(total_cost, previous_period_cost)
        
        # Budget calculations
        budget_remaining = None
        budget_percentage_used = None
        if customer.monthly_budget > 0:
            monthly_cost = total_cost * (30 / days)
            budget_remaining = customer.monthly_budget - monthly_cost
            budget_percentage_used = (monthly_cost / customer.monthly_budget) * 100
        
        return CostSummary(
            customer_id=customer_id,
            period=f"Last {days} days",
            total_cost=total_cost,
            daily_average=daily_average,
            trend=trend,
            percentage_change=percentage_change,
            budget_remaining=budget_remaining,
            budget_percentage_used=budget_percentage_used
        )
    
    except Exception as e:
        logger.error(f"Cost summary failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve cost data: {str(e)}"
        )

@router.get("/{customer_id}/breakdown", response_model=List[CostByResource])
async def get_cost_breakdown(
    customer_id: str,
    days: int = 30,
    group_by: str = "ResourceType",
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get cost breakdown by resource type or name
    """
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")
    
    # Mock data (replace with Azure Cost Management API)
    breakdown = [
        {"resource_type": "Azure Firewall", "resource_name": f"afw-{customer_id}-hub-eus", "cost": 3600.00, "percentage": 23.3},
        {"resource_type": "Log Analytics", "resource_name": f"law-{customer_id}-central", "cost": 2800.00, "percentage": 18.1},
        {"resource_type": "Virtual Machines", "resource_name": "multiple", "cost": 2400.00, "percentage": 15.5},
        {"resource_type": "SQL Database", "resource_name": f"sql-{customer_id}-prod", "cost": 2100.00, "percentage": 13.6},
        {"resource_type": "Storage Accounts", "resource_name": "multiple", "cost": 1800.00, "percentage": 11.7},
        {"resource_type": "Virtual Network", "resource_name": "multiple", "cost": 1200.00, "percentage": 7.8},
        {"resource_type": "Azure Bastion", "resource_name": f"bas-{customer_id}-hub-eus", "cost": 900.00, "percentage": 5.8},
        {"resource_type": "Other", "resource_name": "various", "cost": 632.50, "percentage": 4.1},
    ]
    
    return [CostByResource(**item) for item in breakdown]

@router.get("/{customer_id}/forecast", response_model=List[CostForecast])
async def get_cost_forecast(
    customer_id: str,
    days: int = 30,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get cost forecast for next N days
    """
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")
    
    # Mock forecast data
    forecasts = []
    base_daily_cost = 500.0
    
    for i in range(days):
        date = (datetime.utcnow() + timedelta(days=i)).strftime("%Y-%m-%d")
        # Simple linear forecast with some variation
        forecasted_cost = base_daily_cost * (1 + (i * 0.01))
        confidence = "high" if i < 7 else "medium" if i < 14 else "low"
        
        forecasts.append(CostForecast(
            date=date,
            forecasted_cost=round(forecasted_cost, 2),
            confidence=confidence
        ))
    
    return forecasts

@router.get("/{customer_id}/recommendations", response_model=List[CostRecommendation])
async def get_cost_recommendations(
    customer_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get AI-powered cost optimization recommendations
    """
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")
    
    # Mock recommendations (in production, analyze actual Azure resources)
    recommendations = [
        {
            "resource_id": f"/subscriptions/.../resourceGroups/rg-{customer_id}-prod/providers/Microsoft.Compute/virtualMachines/vm-app-01",
            "resource_name": "vm-app-01",
            "recommendation_type": "rightsizing",
            "current_cost": 120.00,
            "potential_savings": 60.00,
            "savings_percentage": 50.0,
            "description": "VM is underutilized (avg CPU: 15%). Downsize from Standard_D4s_v3 to Standard_D2s_v3.",
            "action": "Downsize to Standard_D2s_v3"
        },
        {
            "resource_id": f"/subscriptions/.../resourceGroups/rg-{customer_id}-prod/providers/Microsoft.Sql/servers/sql-{customer_id}/databases/app-db",
            "resource_name": "app-db",
            "recommendation_type": "scheduling",
            "current_cost": 210.00,
            "potential_savings": 84.00,
            "savings_percentage": 40.0,
            "description": "Database shows no activity on nights/weekends. Enable serverless auto-pause.",
            "action": "Enable serverless with 60-min auto-pause"
        },
        {
            "resource_id": f"/subscriptions/.../resourceGroups/rg-{customer_id}-prod/providers/Microsoft.Compute/disks/disk-unattached-01",
            "resource_name": "disk-unattached-01",
            "recommendation_type": "unused",
            "current_cost": 30.00,
            "potential_savings": 30.00,
            "savings_percentage": 100.0,
            "description": "Disk is unattached for 45+ days. Delete or archive.",
            "action": "Delete unattached disk"
        },
        {
            "resource_id": f"/subscriptions/.../resourceGroups/rg-{customer_id}-prod/providers/Microsoft.OperationalInsights/workspaces/law-{customer_id}-central",
            "resource_name": f"law-{customer_id}-central",
            "recommendation_type": "reserved_instances",
            "current_cost": 2800.00,
            "potential_savings": 700.00,
            "savings_percentage": 25.0,
            "description": "Use commitment tier for Log Analytics (100GB/day). Save 25%.",
            "action": "Enable 100GB commitment tier"
        },
        {
            "resource_id": f"/subscriptions/.../resourceGroups/rg-{customer_id}-prod/providers/Microsoft.Storage/storageAccounts/st{customer_id}prod",
            "resource_name": f"st{customer_id}prod",
            "recommendation_type": "scheduling",
            "current_cost": 450.00,
            "potential_savings": 315.00,
            "savings_percentage": 70.0,
            "description": "90% of data is accessed less than once/month. Move to Cool or Archive tier.",
            "action": "Enable lifecycle management: Hot→Cool after 30 days, Cool→Archive after 90 days"
        }
    ]
    
    return [CostRecommendation(**rec) for rec in recommendations]

@router.post("/{customer_id}/alerts")
async def configure_cost_alerts(
    customer_id: str,
    threshold_percentage: float,
    alert_emails: List[str],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Configure cost alerts for customer
    """
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")
    
    if customer.monthly_budget == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot configure alerts without a budget. Set monthly_budget first."
        )
    
    # Create alert configuration (store in database or Azure)
    alert_config = {
        "customer_id": customer_id,
        "threshold_percentage": threshold_percentage,
        "threshold_amount": customer.monthly_budget * (threshold_percentage / 100),
        "alert_emails": alert_emails,
        "enabled": True
    }
    
    logger.info(f"Cost alert configured for {customer_id}: {threshold_percentage}%")
    
    return {
        "message": "Cost alert configured successfully",
        "config": alert_config
    }

@router.get("/{customer_id}/trends")
async def get_cost_trends(
    customer_id: str,
    months: int = 6,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get historical cost trends (for charts)
    """
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")
    
    # Mock monthly trend data
    trends = []
    base_cost = 12000
    
    for i in range(months):
        month_date = (datetime.utcnow() - timedelta(days=30 * i)).strftime("%Y-%m")
        monthly_cost = base_cost * (1 + (i * 0.05))  # 5% growth per month
        
        trends.insert(0, {
            "month": month_date,
            "cost": round(monthly_cost, 2),
            "budget": customer.monthly_budget,
            "percentage_used": round((monthly_cost / customer.monthly_budget * 100), 1) if customer.monthly_budget > 0 else None
        })
    
    return trends