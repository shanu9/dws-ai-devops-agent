"""
Deployment API
Trigger and manage infrastructure deployments
"""

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
import logging

from database import get_db
from models.customer import Customer
from models.deployment import Deployment
from api.auth import get_current_user
from utils.terraform import TerraformRunner

router = APIRouter()
logger = logging.getLogger(__name__)

# Pydantic models
class DeploymentRequest(BaseModel):
    customer_id: str
    component: str  # management | hub | spoke-production
    action: str = "deploy"  # deploy | destroy | plan
    auto_approve: bool = False

class DeploymentResponse(BaseModel):
    id: int
    customer_id: str
    component: str
    action: str
    status: str
    started_at: str
    
    class Config:
        from_attributes = True

# Background task for deployment
async def run_deployment_task(
    deployment_id: int,
    customer_id: str,
    component: str,
    action: str,
    auto_approve: bool,
    db_session: Session
):
    """
    Background task to run Terraform deployment
    """
    deployment = db_session.query(Deployment).filter(Deployment.id == deployment_id).first()
    deployment.status = "running"
    db_session.commit()
    
    try:
        # Get customer
        customer = db_session.query(Customer).filter(Customer.id == customer_id).first()
        
        # Initialize Terraform runner
        tf_runner = TerraformRunner(customer_id, component, customer)
        
        # Run deployment
        if action == "plan":
            result = tf_runner.plan()
            deployment.terraform_plan = result["plan_output"]
            deployment.status = "completed"
        
        elif action == "deploy":
            # Plan first
            plan_result = tf_runner.plan()
            deployment.terraform_plan = plan_result["plan_output"]
            
            if auto_approve:
                # Apply
                apply_result = tf_runner.apply()
                deployment.terraform_output = apply_result["output"]
                deployment.resources_created = apply_result["resources"]
                deployment.status = "completed"
                
                # Update customer status
                if component == "hub":
                    customer.deployed_at = datetime.utcnow()
                    customer.status = "active"
            else:
                deployment.status = "pending_approval"
        
        elif action == "destroy":
            result = tf_runner.destroy()
            deployment.terraform_output = result["output"]
            deployment.status = "completed"
            
            # Update customer status
            customer.status = "destroyed"
        
        deployment.completed_at = datetime.utcnow()
        deployment.execution_time_seconds = (deployment.completed_at - deployment.started_at).seconds
        
    except Exception as e:
        logger.error(f"Deployment failed: {e}", exc_info=True)
        deployment.status = "failed"
        deployment.error_message = str(e)
        deployment.completed_at = datetime.utcnow()
    
    finally:
        db_session.commit()

# Endpoints
@router.post("/", response_model=DeploymentResponse, status_code=status.HTTP_202_ACCEPTED)
async def create_deployment(
    request: DeploymentRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Trigger new deployment (async)
    """
    # Validate customer exists
    customer = db.query(Customer).filter(Customer.id == request.customer_id).first()
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")
    
    # Validate component
    valid_components = ["management", "hub", "spoke-production", "spoke-development"]
    if request.component not in valid_components:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid component. Must be one of: {valid_components}"
        )
    
    # Create deployment record
    deployment = Deployment(
        customer_id=request.customer_id,
        component=request.component,
        action=request.action,
        status="pending",
        triggered_by=current_user.username
    )
    
    db.add(deployment)
    db.commit()
    db.refresh(deployment)
    
    # Trigger background task
    background_tasks.add_task(
        run_deployment_task,
        deployment.id,
        request.customer_id,
        request.component,
        request.action,
        request.auto_approve,
        db
    )
    
    logger.info(f"Deployment triggered: {deployment.id} for {request.customer_id}/{request.component}")
    
    return deployment.to_dict()

@router.get("/{deployment_id}", response_model=DeploymentResponse)
async def get_deployment(
    deployment_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get deployment status
    """
    deployment = db.query(Deployment).filt