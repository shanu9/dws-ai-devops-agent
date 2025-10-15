"""
Deployments API
GET /api/deployments - List all deployments
GET /api/deployments/{id} - Get deployment details
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from models.customer import Customer
from models.deployment import Deployment

router = APIRouter(prefix="/api/deployments", tags=["deployments"])

@router.get("/")
async def list_deployments(db: Session = Depends(get_db)):
    """List all deployments with customer info"""
    deployments = db.query(Deployment).order_by(Deployment.started_at.desc()).all()
    
    result = []
    for deployment in deployments:
        customer = db.query(Customer).filter(Customer.id == deployment.customer_id).first()
        
        result.append({
            "id": deployment.id,
            "customer_id": customer.customer_id if customer else None,
            "customer_name": customer.customer_name if customer else None,
            "deployment_name": deployment.deployment_name,
            "status": deployment.status,
            "package_tier": deployment.package_tier,
            "progress_percentage": deployment.progress_percentage,
            "current_step": deployment.current_step,
            "github_run_id": deployment.github_run_id,
            "github_run_url": deployment.github_run_url,
            "management_deployed": deployment.management_deployed,
            "hub_deployed": deployment.hub_deployed,
            "spoke_deployed": deployment.spoke_deployed,
            "estimated_monthly_cost": deployment.estimated_monthly_cost,
            "error_message": deployment.error_message,
            "started_at": deployment.started_at,
            "completed_at": deployment.completed_at
        })
    
    return result

@router.get("/{deployment_id}")
async def get_deployment(deployment_id: int, db: Session = Depends(get_db)):
    """Get specific deployment details"""
    deployment = db.query(Deployment).filter(Deployment.id == deployment_id).first()
    
    if not deployment:
        raise HTTPException(status_code=404, detail="Deployment not found")
    
    customer = db.query(Customer).filter(Customer.id == deployment.customer_id).first()
    
    return {
        "id": deployment.id,
        "customer_id": customer.customer_id if customer else None,
        "customer_name": customer.customer_name if customer else None,
        "customer_email": customer.email if customer else None,
        "deployment_name": deployment.deployment_name,
        "status": deployment.status,
        "package_tier": deployment.package_tier,
        "progress_percentage": deployment.progress_percentage,
        "current_step": deployment.current_step,
        "github_run_id": deployment.github_run_id,
        "github_run_url": deployment.github_run_url,
        "management_deployed": deployment.management_deployed,
        "hub_deployed": deployment.hub_deployed,
        "spoke_deployed": deployment.spoke_deployed,
        "estimated_monthly_cost": deployment.estimated_monthly_cost,
        "logs": deployment.logs,
        "error_message": deployment.error_message,
        "started_at": deployment.started_at,
        "completed_at": deployment.completed_at
    }