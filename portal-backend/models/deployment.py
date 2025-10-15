"""
Deployment Model
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, JSON, Float
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime
import enum

# Deployment Status Enum
class DeploymentStatus(str, enum.Enum):
    PENDING = "pending"
    VALIDATING = "validating"
    DEPLOYING_MANAGEMENT = "deploying_management"
    DEPLOYING_HUB = "deploying_hub"
    DEPLOYING_SPOKE = "deploying_spoke"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

class Deployment(Base):
    __tablename__ = "deployments"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=False)

    deployment_name = Column(String(100))
    status = Column(String(50), default="pending")
    package_tier = Column(String(20))

    # GitHub Actions
    github_run_id = Column(String(50), index=True)
    github_run_url = Column(String(500))

    # Progress
    current_step = Column(String(100))
    progress_percentage = Column(Integer, default=0)

    # Terraform State
    management_deployed = Column(Boolean, default=False)
    hub_deployed = Column(Boolean, default=False)
    spoke_deployed = Column(Boolean, default=False)

    # Cost
    estimated_monthly_cost = Column(Float, default=0.0)

    # Logs & Errors
    logs = Column(JSON, default=list)
    error_message = Column(String(1000), nullable=True)

    # Timestamps
    started_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)

    # Relationships
    customer = relationship("Customer", back_populates="deployments")