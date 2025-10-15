"""
Customer Model
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime

class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(String(10), unique=True, index=True, nullable=False)
    customer_name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)

    # Package
    package_tier = Column(String(20), default="standard")
    monthly_cost = Column(Float, default=3500.0)

    # Azure Config
    region = Column(String(50), default="eastus")
    region_code = Column(String(10), default="eus")
    hub_vnet_cidr = Column(String(20), default="10.1.0.0/16")
    spoke_vnet_cidr = Column(String(20), default="10.2.0.0/16")

    # Status
    status = Column(String(20), default="active")
    is_deployed = Column(Boolean, default=False)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    deployments = relationship("Deployment", back_populates="customer", cascade="all, delete-orphan")