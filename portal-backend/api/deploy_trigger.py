"""
Deployment Trigger API
POST /api/deploy - Trigger GitHub Actions workflow
GET /api/deploy/{id} - Get deployment status
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
import requests
import os
from database import get_db
from models.customer import Customer
from models.deployment import Deployment, DeploymentStatus

router = APIRouter(prefix="/api/deploy", tags=["deploy"])

class DeployRequest(BaseModel):
    customer_id: str
    customer_name: str
    customer_email: str
    region: str
    package_tier: str
    hub_vnet_cidr: str = "10.1.0.0/16"
    spoke_vnet_cidr: str = "10.2.0.0/16"

@router.post("/")
async def trigger_deployment(
    request: DeployRequest,
    db: Session = Depends(get_db)
):
    """Trigger GitHub Actions deployment workflow"""
    
    # Check if customer exists
    customer = db.query(Customer).filter(
        Customer.customer_id == request.customer_id
    ).first()
    
    if not customer:
        # Create new customer
        customer = Customer(
            customer_id=request.customer_id,
            customer_name=request.customer_name,
            email=request.customer_email,
            package_tier=request.package_tier,
            region=request.region
        )
        db.add(customer)
        db.commit()
        db.refresh(customer)
    
    # Create deployment record
    deployment = Deployment(
        customer_id=customer.id,
        deployment_name=f"Deploy {request.customer_name}",
        status=DeploymentStatus.PENDING.value,
        package_tier=request.package_tier
    )
    db.add(deployment)
    db.commit()
    db.refresh(deployment)
    
    # Trigger GitHub Actions
    github_token = os.getenv("GITHUB_TOKEN")
    github_repo = os.getenv("GITHUB_REPO")  # e.g., "username/repo"
    
    if not github_token or not github_repo:
        # For testing without GitHub integration
        deployment.status = DeploymentStatus.VALIDATING.value
        deployment.github_run_url = "https://github.com/actions"
        db.commit()
        
        return {
            "deployment_id": deployment.id,
            "status": "triggered",
            "message": "Deployment started (GitHub integration not configured)",
            "github_url": deployment.github_run_url
        }
    
    url = f"https://api.github.com/repos/{github_repo}/actions/workflows/deploy-infrastructure.yml/dispatches"
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {github_token}",
        "X-GitHub-Api-Version": "2022-11-28"
    }
    payload = {
        "ref": "main",
        "inputs": {
            "customer_id": request.customer_id,
            "customer_name": request.customer_name,
            "customer_email": request.customer_email,
            "region": request.region,
            "package_tier": request.package_tier,
            "hub_vnet_cidr": request.hub_vnet_cidr,
            "spoke_vnet_cidr": request.spoke_vnet_cidr
        }
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        
        if response.status_code != 204:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to trigger deployment: {response.text}"
            )
        
        # Update deployment with GitHub info
        deployment.status = DeploymentStatus.VALIDATING.value
        deployment.github_run_url = f"https://github.com/{github_repo}/actions"
        db.commit()
        
        return {
            "deployment_id": deployment.id,
            "status": "triggered",
            "message": "Deployment started successfully",
            "github_url": deployment.github_run_url
        }
    except Exception as e:
        deployment.status = DeploymentStatus.FAILED.value
        deployment.error_message = str(e)
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{deployment_id}")
async def get_deployment_status(
    deployment_id: int,
    db: Session = Depends(get_db)
):
    """Get deployment status"""
    deployment = db.query(Deployment).filter(
        Deployment.id == deployment_id
    ).first()
    
    if not deployment:
        raise HTTPException(status_code=404, detail="Deployment not found")
    
    customer = db.query(Customer).filter(
        Customer.id == deployment.customer_id
    ).first()
    
    return {
        "id": deployment.id,
        "customer_name": customer.customer_name,
        "customer_id": customer.customer_id,
        "package_tier": deployment.package_tier,
        "status": deployment.status,
        "progress_percentage": deployment.progress_percentage,
        "current_step": deployment.current_step,
        "github_run_url": deployment.github_run_url,
        "started_at": deployment.started_at,
        "completed_at": deployment.completed_at,
        "error_message": deployment.error_message
    }