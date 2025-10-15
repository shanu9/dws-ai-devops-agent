"""
Customer Management API
CRUD operations for customers
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel, EmailStr, Field
import logging

from database import get_db
from models.customer import Customer
from api.auth import get_current_user
from utils.encryption import encrypt_value, decrypt_value

router = APIRouter()
logger = logging.getLogger(__name__)

# Pydantic models for request/response
class CustomerCreate(BaseModel):
    id: str = Field(..., min_length=3, max_length=6, pattern="^[a-z0-9]+$")
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    phone: Optional[str] = None
    
    # Azure config
    tenant_id: str
    subscription_ids: dict
    sp_client_id: str
    sp_client_secret: str
    
    # Network config
    region: str
    region_code: str
    environment: str = "prd"
    hub_vnet_cidr: str = "10.0.0.0/16"
    spoke_vnets: dict = {"production": "10.2.0.0/16"}
    
    # Features
    enable_bastion: bool = True
    enable_vpn_gateway: bool = False
    firewall_sku: str = "Standard"
    
    # Services (per spoke)
    services_config: dict = {}
    
    # Cost
    cost_center: Optional[str] = None
    monthly_budget: int = 0
    
    tags: Optional[dict] = {}
    notes: Optional[str] = None

class CustomerUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    monthly_budget: Optional[int] = None
    services_config: Optional[dict] = None
    tags: Optional[dict] = None
    notes: Optional[str] = None

class CustomerResponse(BaseModel):
    id: str
    name: str
    email: str
    region: str
    status: str
    created_at: str
    deployed_at: Optional[str]
    monthly_budget: int
    
    class Config:
        from_attributes = True

# Endpoints
@router.post("/", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
async def create_customer(
    customer: CustomerCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Create new customer
    """
    # Check if customer already exists
    existing = db.query(Customer).filter(Customer.id == customer.id).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Customer {customer.id} already exists"
        )
    
    # Encrypt sensitive data
    encrypted_secret = encrypt_value(customer.sp_client_secret)
    
    # Create customer record
    db_customer = Customer(
        id=customer.id,
        name=customer.name,
        email=customer.email,
        phone=customer.phone,
        tenant_id=customer.tenant_id,
        subscription_ids=customer.subscription_ids,
        sp_client_id=customer.sp_client_id,
        sp_client_secret=encrypted_secret,
        region=customer.region,
        region_code=customer.region_code,
        environment=customer.environment,
        hub_vnet_cidr=customer.hub_vnet_cidr,
        spoke_vnets=customer.spoke_vnets,
        enable_bastion=customer.enable_bastion,
        enable_vpn_gateway=customer.enable_vpn_gateway,
        firewall_sku=customer.firewall_sku,
        services_config=customer.services_config,
        cost_center=customer.cost_center or f"{customer.id}-{customer.environment}",
        monthly_budget=customer.monthly_budget,
        tags=customer.tags,
        notes=customer.notes,
        status="created"
    )
    
    db.add(db_customer)
    db.commit()
    db.refresh(db_customer)
    
    logger.info(f"Customer created: {customer.id} by {current_user.username}")
    
    return db_customer.to_dict()

@router.get("/", response_model=List[CustomerResponse])
async def list_customers(
    skip: int = 0,
    limit: int = 100,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    List all customers (with pagination)
    """
    query = db.query(Customer)
    
    if status:
        query = query.filter(Customer.status == status)
    
    customers = query.offset(skip).limit(limit).all()
    
    return [c.to_dict() for c in customers]

@router.get("/{customer_id}", response_model=CustomerResponse)
async def get_customer(
    customer_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get customer by ID
    """
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Customer {customer_id} not found"
        )
    
    return customer.to_dict()

@router.patch("/{customer_id}", response_model=CustomerResponse)
async def update_customer(
    customer_id: str,
    updates: CustomerUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Update customer
    """
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Customer {customer_id} not found"
        )
    
    # Update fields
    update_data = updates.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(customer, field, value)
    
    db.commit()
    db.refresh(customer)
    
    logger.info(f"Customer updated: {customer_id} by {current_user.username}")
    
    return customer.to_dict()

@router.delete("/{customer_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_customer(
    customer_id: str,
    force: bool = False,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Delete customer (soft delete by default)
    """
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Customer {customer_id} not found"
        )
    
    if customer.status == "active" and not force:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete active customer. Use force=true to override."
        )
    
    if force:
        db.delete(customer)
    else:
        customer.status = "deleted"
    
    db.commit()
    
    logger.warning(f"Customer deleted: {customer_id} by {current_user.username} (force={force})")
    
    return None

@router.get("/{customer_id}/config")
async def get_customer_config(
    customer_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Get customer configuration for Terraform
    """
    customer = db.query(Customer).filter(Customer.id == customer_id).first()
    
    if not customer:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Customer not found")
    
    # Generate Terraform-ready config
    config = {
        "customer_id": customer.id,
        "environment": customer.environment,
        "region": customer.region,
        "region_code": customer.region_code,
        "hub_vnet_cidr": customer.hub_vnet_cidr,
        "spoke_vnets": customer.spoke_vnets,
        "enable_bastion": customer.enable_bastion,
        "enable_vpn_gateway": customer.enable_vpn_gateway,
        "firewall_sku": customer.firewall_sku,
        "services": customer.services_config,
        "cost_center": customer.cost_center,
        "monthly_budget": customer.monthly_budget,
        "alert_email": customer.email
    }
    
    return config
